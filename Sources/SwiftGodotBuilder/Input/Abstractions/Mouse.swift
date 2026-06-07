//
//  Mouse.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

public enum Mouse {
    static func button(_ button: MouseButton) -> InputEventMouseButton {
        .init(button)
    }
}
