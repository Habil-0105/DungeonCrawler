//
//  Enemy.swift
//  DungeonCrawler
//
//  Created by habil on 11/07/26.
//

import SpriteKit

enum EnemyType: CaseIterable {
    case chaser
    case guardian
    case coward
    
    var baseHP: Int {
        switch self {
        case .chaser: return 3
        case .guardian: return 5
        case .coward: return 2
        }
    }
    
    var attackPower: Int {
        switch self {
        case .chaser: return 1
        case .guardian: return 2
        case .coward: return 1
        }
    }
    
    var detectionRadius: Int {
        switch self {
        case .chaser: return 6
        case .guardian: return 1
        case .coward: return 5
        }
    }
    
    var idleImageName: String {
        "enemy_idle"
//        switch self {
//        case .chaser: return "enemy_chaser_idle"
//        case .guardian: return "enemy_guardian_idle"
//        case .coward: return "enemy_coward_idle"
//        }
    }
}

class Enemy{
    var gridPos: (x: Int, y: Int)
    let node: SKSpriteNode
    var hp: Int
    let maxHP: Int
    let attackPower: Int
    let type: EnemyType
    let detectionRadius: Int
    
    init(gridPos: (x: Int, y: Int), type: EnemyType){
        self.gridPos = gridPos
        self.type = type
        self.hp = type.baseHP
        self.maxHP = type.baseHP
        self.attackPower = type.attackPower
        self.detectionRadius = type.detectionRadius
        
        node = SKSpriteNode(imageNamed: type.idleImageName)
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
