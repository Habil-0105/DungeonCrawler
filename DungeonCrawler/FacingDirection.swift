//
//  FacingDirection.swift
//  DungeonCrawler
//
//  Created by habil on 19/07/26.
//

import CoreGraphics

enum FacingDirection: CaseIterable{
    case up
    case down
    case left
    case right
    
    var spriteSuffix: String{
        switch self {
        case .up: return "up"
        case .down: return "down"
        case .left, .right: return "left"
        }
    }
    
    var xScaleMultiplier: CGFloat {
        self == .right ? -1 : 1
    }
    
    static func from(dx: Int, dy: Int) -> FacingDirection? {
        if dx == -1 && dy == 0 { return .left }
        if dx == 1 && dy == 0 { return .right }
        if dy == 1 && dx == 0 { return .up }
        if dy == -1 && dx == 0 { return .down }
        return nil
    }
}
