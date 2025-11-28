//
//  DOM.Element.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 31/12/16.
//  Copyright 2020 Simon Whitty
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

import Foundation

public protocol ContainerElement {
    var childElements: [DOM.GraphicsElement] { get set }
}

public protocol ElementAttributes {
    var id: String?  { get set }
    var `class`: String?  { get set }
}

public extension DOM {

    class Element {}
    
    class GraphicsElement: Element, ElementAttributes {
        public var id: String?
        public var `class`: String?

        public var attributes = PresentationAttributes()
        public var style = PresentationAttributes()
    }
    
    final class Line: GraphicsElement {
        public var x1: Coordinate
        public var y1: Coordinate
        public var x2: Coordinate
        public var y2: Coordinate

        public init(x1: Coordinate, y1: Coordinate, x2: Coordinate, y2: Coordinate) {
            self.x1 = x1
            self.y1 = y1
            self.x2 = x2
            self.y2 = y2
            super.init()
        }
    }
    
    final class Circle: GraphicsElement {
        public var cx: Coordinate?
        public var cy: Coordinate?
        public var r: Coordinate

        public init(cx: Coordinate?, cy: Coordinate?, r: Coordinate) {
            self.cx = cx
            self.cy = cy
            self.r = r
            super.init()
        }
    }
    
    final class Ellipse: GraphicsElement {
        public var cx: Coordinate?
        public var cy: Coordinate?
        public var rx: Coordinate
        public var ry: Coordinate

        public init(cx: Coordinate?, cy: Coordinate?, rx: Coordinate, ry: Coordinate) {
            self.cx = cx
            self.cy = cy
            self.rx = rx
            self.ry = ry
            super.init()
        }
    }
    
    final class Rect: GraphicsElement {
        public var x: Coordinate?
        public var y: Coordinate?
        public var width: Coordinate
        public var height: Coordinate

        public var rx: Coordinate?
        public var ry: Coordinate?

        public init(x: Coordinate? = nil, y: Coordinate? = nil, width: Coordinate, height: Coordinate) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            super.init()
        }
    }
    
    final class Polyline: GraphicsElement {
        public var points: [Point]

        public init(points: [Point]) {
            self.points = points
            super.init()
        }
    }
    
    final class Polygon: GraphicsElement {
        public var points: [Point]

        public init(points: [Point]) {
            self.points = points
            super.init()
        }
    }
    
    final class Group: GraphicsElement, ContainerElement {
        public var childElements = [GraphicsElement]()
    }
}
