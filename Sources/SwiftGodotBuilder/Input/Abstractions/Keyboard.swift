//
//  Keyboard.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

public enum Keyboard {
    static func key(_ key: Key) -> InputEventKey {
        .init(key)
    }
}
