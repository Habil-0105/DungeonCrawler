//
//  Pathfinder.swift
//  DungeonCrawler
//
//  Created by habil on 13/07/26.
//

import Foundation

struct Pathfinder{
    let grid: [[TileType]]
    let width: Int
    let height: Int
    
    func nextStep(from start: (x: Int, y: Int), to target: (x: Int, y: Int)) -> (dx: Int, dy: Int)? {
        if start == target { return nil }
        
        var visited = Set<String>()
        var queue: [(pos: (x: Int, y: Int), path: [(x: Int, y: Int)])] = []
        queue.append((start, [start]))
        visited.insert(key(start))
        
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if current.pos == target {
                guard current.path.count > 1 else { return nil }
                let firstStep = current.path[1]
                return (dx: firstStep.x - start.x, dy: firstStep.y - start.y)
            }
            
            for dir in directions {
                let next = (x: current.pos.x + dir.0, y: current.pos.y + dir.1)
                
                guard next.x >= 0, next.x < width, next.y >= 0, next.y < height else { continue }
                guard grid[next.y][next.x] != .wall else { continue }
                guard !visited.contains(key(next)) else { continue }
                
                visited.insert(key(next))
                queue.append((next, current.path + [next]))
            }
        }
        
        return nil
    }
    
    private func key(_ pos: (x: Int, y: Int)) -> String {
        "\(pos.x),\(pos.y)"
    }
}
