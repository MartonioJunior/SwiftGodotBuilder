import Foundation
import SwiftGodot

/// Real-time bfxr audio synthesizer
/// Based on the official bfxr JavaScript implementation
public class BfxrSynthesizer {
    // MARK: - Parameters

    public var params: BfxrParams

    // MARK: - Synthesis State

    // Frequency/period
    private var period: Double = 0.0 // Period in samples
    private var maxPeriod: Double = 0.0
    private var slide: Double = 0.0
    private var deltaSlide: Double = 0.0

    // Phase (integer sample position within period)
    private var phase: Int = 0

    // Envelope
    private var envelopeStage: Int = 0
    private var envelopeTime: Int = 0
    private var envelopeLength: [Double] = [0, 0, 0]
    private var envelopeVolume: Double = 0.0

    // Vibrato
    private var vibratoPhase: Double = 0.0
    private var vibratoSpeed: Double = 0.0
    private var vibratoAmplitude: Double = 0.0

    // Pitch jump
    private var pitchJump: Double = 1.0
    private var pitchJumpTime: Int = 0
    private var pitchJumpReached: Bool = false

    // Filters
    private var lpFilterPos: Double = 0.0
    private var lpFilterOldPos: Double = 0.0
    private var lpFilterDeltaPos: Double = 0.0
    private var lpFilterCutoff: Double = 0.0
    private var lpFilterDeltaCutoff: Double = 0.0
    private var lpFilterDamping: Double = 0.0
    private var lpFilterOn: Bool = false

    private var hpFilterPos: Double = 0.0
    private var hpFilterCutoff: Double = 0.0

    // Noise
    private var noiseBuffer: [Double] = []

    // Compression
    private var compressionFactor: Double = 1.0
    private var masterVolume: Double = 0.5

    // Sample tracking
    private var sampleIndex: Int = 0
    private var totalSamples: Int = 0
    private var muted: Bool = false

    // Sample rate
    private let sampleRate: Double

    // MARK: - Initialization

    public init(params: BfxrParams, sampleRate: Double = 44100.0) {
        self.params = params
        self.sampleRate = sampleRate
        reset()
    }

    /// Reset synthesizer to initial state
    public func reset() {
        // Calculate period from frequency
        let fStart = params.frequency_start
        period = 100.0 / (fStart * fStart + 0.001)

        let fMin = pow(params.min_frequency_relative_to_starting_frequency, 0.4) * params.frequency_start
        maxPeriod = 100.0 / (fMin * fMin + 0.001)

        // Slide/acceleration
        slide = 1.0 - params.frequency_slide * params.frequency_slide * params.frequency_slide * 0.01
        deltaSlide = -params.frequency_acceleration * params.frequency_acceleration * params.frequency_acceleration * 0.000001

        // Envelope - squared time * 100000
        envelopeLength[0] = params.attackTime * params.attackTime * 100_000.0
        envelopeLength[1] = params.sustainTime * params.sustainTime * 100_000.0
        envelopeLength[2] = params.decayTime * params.decayTime * 100_000.0 + 10

        totalSamples = Int(envelopeLength[0] + envelopeLength[1] + envelopeLength[2])

        // Vibrato
        vibratoPhase = 0.0
        vibratoSpeed = params.vibratoSpeed * params.vibratoSpeed * 0.01
        vibratoAmplitude = params.vibratoDepth * 0.5

        // Pitch jump
        pitchJumpReached = false
        if params.pitch_jump_amount > 0.0 {
            pitchJump = 1.0 - params.pitch_jump_amount * params.pitch_jump_amount * 0.9
        } else {
            pitchJump = 1.0 + params.pitch_jump_amount * params.pitch_jump_amount * 10.0
        }
        pitchJumpTime = Int(params.pitch_jump_onset_percent * Double(totalSamples))

        // Filters
        lpFilterPos = 0.0
        lpFilterDeltaPos = 0.0
        lpFilterCutoff = params.lpFilterCutoff * params.lpFilterCutoff * params.lpFilterCutoff * 0.1
        lpFilterDeltaCutoff = 1.0 + params.lpFilterCutoffSweep * 0.0001
        lpFilterDamping = 5.0 / (1.0 + params.lpFilterResonance * params.lpFilterResonance * 20.0) * (0.01 + lpFilterCutoff)
        if lpFilterDamping > 0.8 { lpFilterDamping = 0.8 }
        lpFilterDamping = 1.0 - lpFilterDamping
        lpFilterOn = params.lpFilterCutoff != 1.0

        hpFilterPos = 0.0
        hpFilterCutoff = params.hpFilterCutoff * params.hpFilterCutoff * 0.1

        // Volume & compression
        masterVolume = params.masterVolume * params.masterVolume
        compressionFactor = 1.0 / (1.0 + 4.0 * params.compressionAmount)

        // Reset state
        phase = 0
        envelopeStage = 0
        envelopeTime = 0
        envelopeVolume = 0.0
        sampleIndex = 0
        muted = false

        // Generate noise
        noiseBuffer = (0 ..< 32).map { _ in Double.random(in: -1.0 ... 1.0) }
    }

    /// Check if synthesis is complete
    public var isFinished: Bool {
        return sampleIndex >= totalSamples
    }

    // MARK: - Sample Generation

    /// Generate next audio sample (with 8x supersampling)
    public func generateSample() -> Double {
        guard !isFinished else { return 0.0 }

        // Apply pitch jump
        if !pitchJumpReached && sampleIndex >= pitchJumpTime {
            pitchJumpReached = true
            period *= pitchJump
        }

        // Apply slide and acceleration
        slide += deltaSlide
        period *= slide

        // Clamp period and check for muting
        if period > maxPeriod {
            period = maxPeriod
            if params.min_frequency_relative_to_starting_frequency > 0.0 {
                muted = true
            }
        }

        // Apply vibrato
        var periodTemp = period
        if vibratoAmplitude > 0.0 {
            vibratoPhase += vibratoSpeed
            periodTemp = period * (1.0 + sin(vibratoPhase) * vibratoAmplitude)
        }

        periodTemp = max(8.0, Double(Int(periodTemp)))

        // 8x supersampling
        var superSample = 0.0
        for _ in 0 ..< 8 {
            phase += 1
            if Double(phase) >= periodTemp {
                phase = 0
                // Regenerate noise
                if params.waveType == 3 {
                    noiseBuffer = (0 ..< 32).map { _ in Double.random(in: -1.0 ... 1.0) }
                }
            }

            // Generate waveform sample
            let sample = generateWaveform(phase: phase, period: Int(periodTemp))

            // Apply filters
            let filtered = applyFilters(sample)

            superSample += filtered
        }

        // Clamp
        superSample = min(8.0, max(-8.0, superSample))

        // Update envelope
        updateEnvelope()

        // Apply envelope and master volume
        superSample = masterVolume * envelopeVolume * superSample * 0.125 // 0.125 = 1/8 for supersampling

        // Apply compression
        if superSample > 0 {
            superSample = pow(superSample, compressionFactor)
        } else {
            superSample = -pow(-superSample, compressionFactor)
        }

        // Check if muted
        if muted {
            superSample = 0.0
        }

        sampleIndex += 1

        return min(1.0, max(-1.0, superSample))
    }

    // MARK: - Waveform Generation

    private func generateWaveform(phase: Int, period: Int) -> Double {
        let pos = Double(phase) / Double(period)

        switch params.waveType {
        case 0: // Square
            return pos < 0.5 ? 0.5 : -0.5

        case 1: // Sawtooth
            return 1.0 - pos * 2.0

        case 2: // Sine (fast approximation)
            var p = pos > 0.5 ? (pos - 1.0) * 6.28318531 : pos * 6.28318531
            let sign = p < 0
            if sign { p = -p }
            var s = p < 0 ? 1.27323954 * p + 0.405284735 * p * p : 1.27323954 * p - 0.405284735 * p * p
            s = s < 0 ? 0.225 * (s * -s - s) + s : 0.225 * (s * s - s) + s
            return sign ? -s : s

        case 3: // White noise
            let idx = (phase * 32 / period) % 32
            return noiseBuffer[idx]

        case 4: // Triangle
            return abs(1.0 - pos * 2.0) - 1.0

        case 5: // Pink noise (simplified)
            let idx = (phase * 32 / period) % 32
            return noiseBuffer[idx] * 0.7

        default:
            return 0.0
        }
    }

    // MARK: - Filters

    private func applyFilters(_ sample: Double) -> Double {
        var output = sample

        // Low-pass filter
        lpFilterOldPos = lpFilterPos
        lpFilterCutoff *= lpFilterDeltaCutoff
        lpFilterCutoff = min(0.1, max(0.0, lpFilterCutoff))

        if lpFilterOn {
            lpFilterDeltaPos += (output - lpFilterPos) * lpFilterCutoff
            lpFilterDeltaPos *= lpFilterDamping
        } else {
            lpFilterPos = output
            lpFilterDeltaPos = 0.0
        }

        lpFilterPos += lpFilterDeltaPos

        // High-pass filter
        hpFilterPos += lpFilterPos - lpFilterOldPos
        hpFilterPos *= 1.0 - hpFilterCutoff
        output = hpFilterPos

        return output
    }

    // MARK: - Envelope

    private func updateEnvelope() {
        envelopeTime += 1

        if Double(envelopeTime) > envelopeLength[envelopeStage] {
            envelopeTime = 0
            envelopeStage += 1
        }

        switch envelopeStage {
        case 0: // Attack
            envelopeVolume = Double(envelopeTime) / envelopeLength[0]
        case 1: // Sustain
            envelopeVolume = 1.0 + (1.0 - Double(envelopeTime) / envelopeLength[1]) * 2.0 * params.sustainPunch
        case 2: // Decay
            envelopeVolume = 1.0 - Double(envelopeTime) / envelopeLength[2]
        default: // Finished
            envelopeVolume = 0.0
        }
    }

    // MARK: - Bulk Generation

    /// Generate all samples at once (for pre-generation)
    public func generateAll() -> [Double] {
        reset()
        var samples: [Double] = []
        samples.reserveCapacity(totalSamples)

        while !isFinished {
            samples.append(generateSample())
        }

        return samples
    }
}
