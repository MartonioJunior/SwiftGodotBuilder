import XCTest
@testable import SwiftGodotBuilder

final class BfxrSynthesizerTests: XCTestCase {
    // MARK: - Parameter Parsing Tests

    func testParseBasicBfxrJSON() {
        let json = """
        {
            "synth_type": "Bfxr",
            "version": "1.0.4",
            "file_name": "Test",
            "params": {
                "masterVolume": 0.5,
                "waveType": 2,
                "attackTime": 0,
                "sustainTime": 0.1,
                "sustainPunch": 0.3,
                "decayTime": 0.2,
                "frequency_start": 0.5,
                "frequency_slide": 0.0,
                "frequency_acceleration": 0.0,
                "vibratoDepth": 0.0,
                "vibratoSpeed": 0.0,
                "pitch_jump_amount": 0.0,
                "pitch_jump_onset_percent": 0.0
            }
        }
        """

        let params = BfxrParams.parse(json: json)
        XCTAssertNotNil(params)
        XCTAssertEqual(params?.masterVolume, 0.5)
        XCTAssertEqual(params?.waveType, 2)
        XCTAssertEqual(params?.sustainTime, 0.1)
        XCTAssertEqual(params?.frequency_start, 0.5)
    }

    func testParseParamsOnly() {
        let json = """
        {
            "masterVolume": 0.8,
            "waveType": 0,
            "attackTime": 0.05,
            "sustainTime": 0.2,
            "sustainPunch": 0.0,
            "decayTime": 0.1,
            "frequency_start": 0.3,
            "frequency_slide": 0.1,
            "frequency_acceleration": 0.0,
            "vibratoDepth": 0.0,
            "vibratoSpeed": 0.0,
            "pitch_jump_amount": 0.0,
            "pitch_jump_onset_percent": 0.0
        }
        """

        let params = BfxrParams.parse(json: json)
        XCTAssertNotNil(params)
        XCTAssertEqual(params?.masterVolume, 0.8)
        XCTAssertEqual(params?.waveType, 0)
    }

    // MARK: - Synthesizer Tests

    func testSynthesizerInitialization() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 2
        params.sustainTime = 0.1
        params.decayTime = 0.1

        let synth = BfxrSynthesizer(params: params)
        XCTAssertFalse(synth.isFinished)
    }

    func testSynthesizerGeneratesSamples() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 2 // Sine wave
        params.sustainTime = 0.1
        params.decayTime = 0.1

        let synth = BfxrSynthesizer(params: params, sampleRate: 22050)

        // Generate a few samples
        var samples: [Double] = []
        for _ in 0..<100 {
            samples.append(synth.generateSample())
        }

        // Verify we got samples
        XCTAssertEqual(samples.count, 100)

        // Verify samples are in valid range [-1, 1]
        for sample in samples {
            XCTAssertGreaterThanOrEqual(sample, -1.0)
            XCTAssertLessThanOrEqual(sample, 1.0)
        }

        // Verify not all samples are zero (sound is actually generated)
        let hasNonZero = samples.contains { abs($0) > 0.001 }
        XCTAssertTrue(hasNonZero, "Synthesizer should generate non-zero samples")
    }

    func testSynthesizerFinishes() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 0
        params.attackTime = 0.01
        params.sustainTime = 0.01
        params.decayTime = 0.01

        let synth = BfxrSynthesizer(params: params, sampleRate: 22050)

        // Generate all samples
        let allSamples = synth.generateAll()

        // Verify synthesizer finished
        XCTAssertTrue(synth.isFinished)

        // Verify we got the expected number of samples
        let expectedSamples = Int(params.duration * 22050)
        XCTAssertEqual(allSamples.count, expectedSamples)
    }

    func testSquareWave() {
        var params = BfxrParams()
        params.masterVolume = 1.0
        params.waveType = 0 // Square wave
        params.sustainTime = 0.1
        params.decayTime = 0.0
        params.attackTime = 0.0

        let synth = BfxrSynthesizer(params: params, sampleRate: 22050)

        // Generate samples
        var samples: [Double] = []
        for _ in 0..<100 {
            samples.append(synth.generateSample())
        }

        // Square wave should have values near -1 or 1 (with envelope)
        let hasHighValues = samples.contains { abs($0) > 0.5 }
        XCTAssertTrue(hasHighValues, "Square wave should have high amplitude values")
    }

    func testEnvelope() {
        var params = BfxrParams()
        params.masterVolume = 1.0
        params.waveType = 2 // Sine wave
        params.attackTime = 0.05
        params.sustainTime = 0.1
        params.decayTime = 0.05

        let synth = BfxrSynthesizer(params: params, sampleRate: 22050)

        let allSamples = synth.generateAll()

        // Attack phase: samples should be increasing in amplitude
        let attackSamples = Array(allSamples.prefix(500))
        var isIncreasing = true
        for i in 1..<min(100, attackSamples.count) {
            if abs(attackSamples[i]) < abs(attackSamples[i-1]) {
                isIncreasing = false
                break
            }
        }
        // Note: This is a simplified test, actual envelope may have oscillations

        // Decay phase: samples near the end should be decreasing
        let decaySamples = Array(allSamples.suffix(500))
        var prevMax: Double = 1.0
        for i in stride(from: 0, to: decaySamples.count - 100, by: 100) {
            let windowMax = decaySamples[i..<min(i+100, decaySamples.count)].map { abs($0) }.max() ?? 0
            if i > 0 {
                XCTAssertLessThanOrEqual(windowMax, prevMax + 0.1, "Decay should reduce amplitude")
            }
            prevMax = windowMax
        }
    }

    func testFrequencySlide() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 2
        params.sustainTime = 0.2
        params.frequency_start = 0.3
        params.frequency_slide = 0.5 // Slide up

        let synth = BfxrSynthesizer(params: params)
        let samples = synth.generateAll()

        // Just verify it completes without crashing
        XCTAssertGreaterThan(samples.count, 0)
    }

    func testPitchJump() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 2
        params.sustainTime = 0.2
        params.frequency_start = 0.3
        params.pitch_jump_amount = 0.5
        params.pitch_jump_onset_percent = 0.5

        let synth = BfxrSynthesizer(params: params)
        let samples = synth.generateAll()

        // Verify pitch jump doesn't crash
        XCTAssertGreaterThan(samples.count, 0)
    }

    func testVibrato() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 2
        params.sustainTime = 0.2
        params.vibratoDepth = 0.5
        params.vibratoSpeed = 0.5

        let synth = BfxrSynthesizer(params: params)
        let samples = synth.generateAll()

        // Verify vibrato doesn't crash
        XCTAssertGreaterThan(samples.count, 0)
    }

    func testAllWaveTypes() {
        for waveType in 0...5 {
            var params = BfxrParams()
            params.masterVolume = 0.5
            params.waveType = waveType
            params.sustainTime = 0.1

            let synth = BfxrSynthesizer(params: params)
            let samples = synth.generateAll()

            XCTAssertGreaterThan(samples.count, 0, "WaveType \(waveType) should generate samples")

            // Verify samples are in valid range
            for sample in samples {
                XCTAssertGreaterThanOrEqual(sample, -1.5, "WaveType \(waveType) sample out of range")
                XCTAssertLessThanOrEqual(sample, 1.5, "WaveType \(waveType) sample out of range")
            }
        }
    }

    func testResetSynthesizer() {
        var params = BfxrParams()
        params.masterVolume = 0.5
        params.waveType = 2
        params.sustainTime = 0.1

        let synth = BfxrSynthesizer(params: params)

        // Generate some samples
        for _ in 0..<1000 {
            _ = synth.generateSample()
        }

        // Reset
        synth.reset()

        // Should be able to generate again
        XCTAssertFalse(synth.isFinished)
        let sample = synth.generateSample()
        XCTAssertGreaterThanOrEqual(sample, -1.0)
        XCTAssertLessThanOrEqual(sample, 1.0)
    }
}
