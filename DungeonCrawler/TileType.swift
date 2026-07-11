//
//  TileType.swift
//  DungeonCrawler
//
//  Created by habil on 11/07/26.
//

enum TileType{
    case floor
    case wall
    
    var imageName: String{
        switch self {
        case .floor: return "tile_floor"
        case .wall: return "tile_wall"
        }
    }
}
