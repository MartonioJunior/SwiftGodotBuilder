import SwiftGodot

/// Custom AudioStreamPlayer for bfxr sound synthesis
@Godot
public class BfxrSound: AudioStreamPlayer {
    // MARK: - Properties

    /// Path to the bfxr JSON file
    public var bfxrPath: String = "" {
        didSet {
            if bfxrPath != oldValue {
                loadBfxrFile()
            }
        }
    }

    /// Bfxr parameters
    private var bfxrParams: BfxrParams?

    /// Voice pool for polyphony
    private var voices: [BfxrSynthesizer?] = []
    private var voiceActive: [Bool] = []

    /// Maximum number of simultaneous sounds (polyphony)
    private let maxVoices: Int = 4

    /// Next voice to use (round-robin allocation)
    private var nextVoiceIndex: Int = 0

    /// Audio playback for pushing frames
    private var playback: AudioStreamGeneratorPlayback?

    /// Sample rate for synthesis (must match bfxr standard)
    private let synthSampleRate: Double = 44100.0

    // MARK: - Parameter Overrides

    /// Runtime parameter overrides (for reactive bindings)
    var masterVolumeOverride: Double?
    var frequencyStartOverride: Double?
    var pitchJumpAmountOverride: Double?
    var vibratoDepthOverride: Double?
    var waveTypeOverride: Int?

    // MARK: - Lifecycle

    override public func _ready() {
        setupAudioStream()
    }

    override public func _process(delta _: Double) {
        guard let playback = playback else {
            return
        }

        // Check if any voices are active
        let hasActiveVoices = voiceActive.contains(true)
        guard hasActiveVoices else {
            return
        }

        // Fill the audio buffer
        let framesAvailable = playback.getFramesAvailable()

        for _ in 0 ..< framesAvailable {
            var mixedSample = 0.0

            // Mix all active voices
            for i in 0 ..< maxVoices {
                guard voiceActive[i], let synthesizer = voices[i] else {
                    continue
                }

                let sample = synthesizer.generateSample()
                mixedSample += sample

                // Check if this voice finished
                if synthesizer.isFinished {
                    voiceActive[i] = false
                }
            }

            // Normalize mixed sample to prevent clipping
            // With 4 voices max, divide by 2 for headroom
            mixedSample = mixedSample / 2.0

            // Convert to float and create stereo frame
            let floatSample = Float(min(1.0, max(-1.0, mixedSample)))
            _ = playback.pushFrame(Vector2(x: floatSample, y: floatSample))
        }
    }

    // MARK: - Setup

    private func setupAudioStream() {
        // Create AudioStreamGenerator
        let stream = AudioStreamGenerator()
        stream.mixRate = synthSampleRate
        stream.bufferLength = 0.1 // 100ms buffer

        self.stream = stream

        // Get the playback interface
        super.play() // Start the stream player (but synthesizer controls actual playback)
        playback = getStreamPlayback() as? AudioStreamGeneratorPlayback

        // Load initial bfxr file if path is set
        if !bfxrPath.isEmpty {
            loadBfxrFile()
        }
    }

    private func loadBfxrFile() {
        guard !bfxrPath.isEmpty else { return }

        if let params = BfxrParams.load(from: bfxrPath) {
            bfxrParams = params

            // Initialize voice pool
            voices = Array(repeating: nil, count: maxVoices)
            voiceActive = Array(repeating: false, count: maxVoices)

            // Pre-create all voices
            for i in 0 ..< maxVoices {
                voices[i] = createSynthesizer(from: params)
            }
        } else {
            GD.printErr("Failed to load bfxr file: \(bfxrPath)")
        }
    }

    private func createSynthesizer(from params: BfxrParams) -> BfxrSynthesizer {
        var modifiedParams = params

        // Apply runtime overrides
        if let override = masterVolumeOverride {
            modifiedParams.masterVolume = override
        }
        if let override = frequencyStartOverride {
            modifiedParams.frequency_start = override
        }
        if let override = pitchJumpAmountOverride {
            modifiedParams.pitch_jump_amount = override
        }
        if let override = vibratoDepthOverride {
            modifiedParams.vibratoDepth = override
        }
        if let override = waveTypeOverride {
            modifiedParams.waveType = override
        }

        return BfxrSynthesizer(params: modifiedParams, sampleRate: synthSampleRate)
    }

    // MARK: - Playback Control

    /// Play the bfxr sound (uses polyphony - can play multiple instances simultaneously)
    public func playSound(fromPosition _: Double = 0) {
        guard let params = bfxrParams else {
            GD.printErr("Cannot play: No bfxr sound loaded")
            return
        }

        // Find next available voice (round-robin)
        let voiceIndex = nextVoiceIndex
        nextVoiceIndex = (nextVoiceIndex + 1) % maxVoices

        // Create new synthesizer for this voice with current parameter overrides
        voices[voiceIndex] = createSynthesizer(from: params)
        voiceActive[voiceIndex] = true
    }

    /// Stop all playing voices
    public func stopSound() {
        for i in 0 ..< maxVoices {
            voiceActive[i] = false
        }
    }

    /// Check if any voice is currently playing
    public var isPlayingSound: Bool {
        return voiceActive.contains(true)
    }
}

// MARK: - GNode Typealias

public typealias BfxrSound$ = GNode<BfxrSound>

// MARK: - Convenience Initializer Extension

public extension GNode where T == BfxrSound {
    /// Create a BfxrSound node with a bfxr file path
    static func callAsFunction(_ bfxrPath: String) -> GNode<BfxrSound> {
        return GNode<BfxrSound>()
            .configure { node in
                node.bfxrPath = bfxrPath
            }
    }

}
