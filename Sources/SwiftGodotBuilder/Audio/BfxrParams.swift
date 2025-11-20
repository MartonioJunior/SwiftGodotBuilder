import Foundation
import SwiftGodot

/// Parameters for bfxr sound synthesis
public struct BfxrParams: Codable {
    // MARK: - Core Parameters

    /// Master volume (0.0 - 1.0)
    public var masterVolume: Double = 0.5

    /// Wave type: 0=square, 1=sawtooth, 2=sine, 3=noise, 4=triangle, 5=pink noise
    public var waveType: Int = 0

    // MARK: - Envelope

    /// Attack time in seconds (0.0 - 1.0)
    public var attackTime: Double = 0.0

    /// Sustain time in seconds (0.0 - 1.0)
    public var sustainTime: Double = 0.3

    /// Sustain punch - amplitude boost during sustain (0.0 - 1.0)
    public var sustainPunch: Double = 0.0

    /// Decay time in seconds (0.0 - 1.0)
    public var decayTime: Double = 0.1

    // MARK: - Frequency

    /// Starting frequency (0.0 - 1.0, maps to ~20-2000 Hz)
    public var frequency_start: Double = 0.3

    /// Frequency slide amount (-1.0 to 1.0, pitch bend over time)
    public var frequency_slide: Double = 0.0

    /// Frequency slide acceleration (-1.0 to 1.0)
    public var frequency_acceleration: Double = 0.0

    /// Minimum frequency relative to starting frequency (0.0 - 1.0)
    public var min_frequency_relative_to_starting_frequency: Double = 0.0

    // MARK: - Vibrato

    /// Vibrato depth (0.0 - 1.0)
    public var vibratoDepth: Double = 0.0

    /// Vibrato speed in Hz (0.0 - 1.0)
    public var vibratoSpeed: Double = 0.0

    // MARK: - Pitch Jump (Arpeggiation)

    /// Pitch jump amount (-1.0 to 1.0)
    public var pitch_jump_amount: Double = 0.0

    /// When pitch jump occurs (0.0 - 1.0, percentage through sound)
    public var pitch_jump_onset_percent: Double = 0.0

    // MARK: - Filters

    /// Low-pass filter cutoff (0.0 - 1.0)
    public var lpFilterCutoff: Double = 1.0

    /// Low-pass filter cutoff sweep (-1.0 to 1.0)
    public var lpFilterCutoffSweep: Double = 0.0

    /// Low-pass filter resonance (0.0 - 1.0)
    public var lpFilterResonance: Double = 0.0

    /// High-pass filter cutoff (0.0 - 1.0)
    public var hpFilterCutoff: Double = 0.0

    /// High-pass filter cutoff sweep (-1.0 to 1.0)
    public var hpFilterCutoffSweep: Double = 0.0

    // MARK: - Compression

    /// Compression amount (0.0 - 1.0)
    public var compressionAmount: Double = 0.0

    // MARK: - Nested Structure

    struct BfxrFile: Codable {
        let synth_type: String?
        let version: String?
        let file_name: String?
        let params: BfxrParams
    }

    // MARK: - Initialization

    public init() {}

    /// Load bfxr parameters from JSON file
    public static func load(from path: String) -> BfxrParams? {
        guard let file = FileAccess.open(path: path, flags: .read) else {
            GD.printErr("Failed to load bfxr file: \(path)")
            return nil
        }

        let jsonString = file.getAsText()
        file.close()

        return parse(json: jsonString)
    }

    /// Parse bfxr parameters from JSON string
    public static func parse(json: String) -> BfxrParams? {
        guard let data = json.data(using: .utf8) else {
            GD.printErr("Failed to convert JSON string to data")
            return nil
        }

        let decoder = JSONDecoder()

        // Try parsing as full bfxr file first
        if let bfxrFile = try? decoder.decode(BfxrFile.self, from: data) {
            return bfxrFile.params
        }

        // Try parsing as params object directly
        if let params = try? decoder.decode(BfxrParams.self, from: data) {
            return params
        }

        GD.printErr("Failed to parse bfxr JSON")
        return nil
    }

    // MARK: - Computed Properties

    /// Total duration of the sound in seconds
    public var duration: Double {
        return attackTime + sustainTime + decayTime
    }

    /// Starting frequency in Hz (maps 0.0-1.0 to 20-2000 Hz logarithmically)
    public var startFrequencyHz: Double {
        return 20.0 * pow(2.0, frequency_start * 6.644) // ~20 Hz to ~2000 Hz
    }
}
