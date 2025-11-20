import SwiftGodot

// MARK: - Parameter Modifier Extensions

public extension GNode where T == BfxrSound {
    // MARK: - Master Volume

    /// Set master volume (0.0 - 1.0)
    func masterVolume(_ volume: Double) -> Self {
        return configure { node in
            node.masterVolumeOverride = volume
        }
    }

    /// Bind master volume to reactive state (0.0 - 1.0)
    func masterVolume(_ volume: State<Double>) -> Self {
        return onProcess { node, _ in
            node.masterVolumeOverride = volume.wrappedValue
        }
    }

    // MARK: - Wave Type

    /// Set wave type (0=square, 1=sawtooth, 2=sine, 3=noise, 4=triangle, 5=pink noise)
    func waveType(_ type: Int) -> Self {
        return configure { node in
            node.waveTypeOverride = type
        }
    }

    /// Bind wave type to reactive state
    func waveType(_ type: State<Int>) -> Self {
        return onProcess { node, _ in
            node.waveTypeOverride = type.wrappedValue
        }
    }

    // MARK: - Frequency

    /// Set starting frequency (0.0 - 1.0, maps to ~20-2000 Hz)
    func frequency(_ freq: Double) -> Self {
        return configure { node in
            node.frequencyStartOverride = freq
        }
    }

    /// Bind starting frequency to reactive state
    func frequency(_ freq: State<Double>) -> Self {
        return onProcess { node, _ in
            node.frequencyStartOverride = freq.wrappedValue
        }
    }

    // MARK: - Pitch Jump

    /// Set pitch jump amount (-1.0 to 1.0)
    func pitchJumpAmount(_ amount: Double) -> Self {
        return configure { node in
            node.pitchJumpAmountOverride = amount
        }
    }

    /// Bind pitch jump amount to reactive state
    func pitchJumpAmount(_ amount: State<Double>) -> Self {
        return onProcess { node, _ in
            node.pitchJumpAmountOverride = amount.wrappedValue
        }
    }

    // MARK: - Vibrato

    /// Set vibrato depth (0.0 - 1.0)
    func vibratoDepth(_ depth: Double) -> Self {
        return configure { node in
            node.vibratoDepthOverride = depth
        }
    }

    /// Bind vibrato depth to reactive state
    func vibratoDepth(_ depth: State<Double>) -> Self {
        return onProcess { node, _ in
            node.vibratoDepthOverride = depth.wrappedValue
        }
    }

    // MARK: - Convenience: Volume (Alias for masterVolume)

    /// Set volume (0.0 - 1.0) - alias for masterVolume
    func volume(_ volume: Double) -> Self {
        return masterVolume(volume)
    }

    /// Bind volume to reactive state - alias for masterVolume
    func volume(_ volume: State<Double>) -> Self {
        return masterVolume(volume)
    }

    // MARK: - Convenience: Pitch (Alias for frequency)

    /// Set pitch (0.0 - 1.0) - alias for frequency
    func pitch(_ pitch: Double) -> Self {
        return frequency(pitch)
    }

    /// Bind pitch to reactive state - alias for frequency
    func pitch(_ pitch: State<Double>) -> Self {
        return frequency(pitch)
    }
}
