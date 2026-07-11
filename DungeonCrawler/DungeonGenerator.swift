//
//  DungeonGenerator.swift
//  DungeonCrawler
//
//  Created by habil on 11/07/26.
//

import Foundation

struct DungeonGenerator {
    let width: Int
    let height: Int
    
    func generate(steps: Int = 400) -> [[TileType]] {
        var grid = Array(
            repeating: Array(repeating: TileType.wall, count: width),
            count: height
        )
        
        var current = (x: width / 2, y: height / 2)
        grid[current.y][current.x] = .floor
        
        for _ in 0..<steps {
            let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
            let move = directions.randomElement()!
            let next = (x: current.x + move.0, y: current.y + move.1)
            
            guard next.x > 0, next.x < width - 1, next.y > 0, next.y < height - 1 else { continue }
            
            current = next
            grid[current.y][current.x] = .floor
        }
        
        return grid
    }
}
