//
//  DOM.RadialGradient.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 13/8/22.
//  Copyright 2022 Simon Whitty
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/swhitty/SwiftDraw
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

public extension DOM {

    final class RadialGradient: Element {
        public typealias Units = LinearGradient.Units
        
        public var id: String
        public var r: Coordinate?
        public var cx: Coordinate?
        public var cy: Coordinate?
        public var fr: Coordinate?
        public var fx: Coordinate?
        public var fy: Coordinate?

        public var stops: [Stop]
        public var gradientUnits: Units?
        public var gradientTransform: [Transform]

        //references another RadialGradient element id within defs
        public var href: URL?

        public init(id: String) {
            self.id = id
            self.stops = []
            self.gradientTransform = []
        }
        
        public struct Stop: Equatable {
            public var offset: Float
            public var color: Color
            public var opacity: Float

            public init(offset: Float, color: Color, opacity: Opacity = 1.0) {
                self.offset = offset
                self.color = color
                self.opacity = opacity
            }
        }
    }
}

extension DOM.RadialGradient: Equatable {
    public static func ==(lhs: DOM.RadialGradient, rhs: DOM.RadialGradient) -> Bool {
        return lhs.id == rhs.id && lhs.stops == rhs.stops
    }
}
