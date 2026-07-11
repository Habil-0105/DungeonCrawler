//
//  Enemy.swift
//  DungeonCrawler
//
//  Created by habil on 11/07/26.
//

import SpriteKit

class Enemy{
    var gridPos: (x: Int, y: Int)
    let node: SKSpriteNode
    
    init(gridPos: (x: Int, y: Int)){
        self.gridPos = gridPos
        node = SKSpriteNode(color: .systemGreen, size: CGSize(width: GameConstants.tileSize - 4, height: GameConstants.tileSize - 4))
        node.zPosition = 8
        updateNodePosition()
    }
    
    func updateNodePosition(){
        node.position = CGPoint(
            x: CGFloat(gridPos.x) * GameConstants.tileSize + GameConstants.tileSize / 2,
            y: CGFloat(gridPos.y) * GameConstants.tileSize + GameConstants.tileSize / 2
        )
    }
}
