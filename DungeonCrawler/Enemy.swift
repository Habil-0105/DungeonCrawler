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
    var hp: Int = 3
    let attackPower: Int = 1
    
    init(gridPos: (x: Int, y: Int)){
        self.gridPos = gridPos
        node = SKSpriteNode(imageNamed: "enemy_idle")
        node.size = CGSize(width: GameConstants.tileSize, height: GameConstants.tileSize)
        node.zPosition = 8
        node.texture?.filteringMode = .nearest
        updateNodePosition()
    }
    
    func updateNodePosition(){
        node.position = CGPoint(
            x: CGFloat(gridPos.x) * GameConstants.tileSize + GameConstants.tileSize / 2,
            y: CGFloat(gridPos.y) * GameConstants.tileSize + GameConstants.tileSize / 2
        )
    }
}
