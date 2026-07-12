//
//  GameScene.swift
//  DungeonCrawler
//
//  Created by habil on 11/07/26.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var grid: [[TileType]] = []
    
    var player: SKSpriteNode!
    var playerGridPos = (x: GameConstants.gridWidth / 2, y: GameConstants.gridHeight / 2)
    
    var enemies: [Enemy] = []
    
    var playerHP = 10
    let playerAttackPower = 2
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let generator = DungeonGenerator(width: GameConstants.gridWidth, height: GameConstants.gridHeight)
        grid = generator.generate()
        renderGrid()
        setupPlayer()
        spawnEnemies()
    }
    
    func makeTestGrid() -> [[TileType]] {
        var result = Array(
            repeating: Array(repeating: TileType.floor, count: GameConstants.gridWidth),
            count: GameConstants.gridHeight
        )
        
        for x in 0..<GameConstants.gridWidth {
            result[0][x] = .wall
            result[GameConstants.gridHeight - 1][x] = .wall
        }
        
        for y in 0..<GameConstants.gridHeight {
            result[y][0] = .wall
            result[y][GameConstants.gridWidth - 1] = .wall
        }
        
        return result
    }
    
    func renderGrid(){
        for y in 0..<GameConstants.gridHeight {
            for x in 0..<GameConstants.gridWidth {
                let tile = grid[y][x]
                
                let node = SKSpriteNode(imageNamed: tile.imageName)
                node.size = CGSize(width: GameConstants.tileSize, height: GameConstants.tileSize)
                node.position = CGPoint(
                    x: CGFloat(x) * GameConstants.tileSize + GameConstants.tileSize / 2,
                    y: CGFloat(y) * GameConstants.tileSize + GameConstants.tileSize / 2
                )
                node.texture?.filteringMode = .nearest
                node.zPosition = 0
                addChild(node)
            }
        }
    }
    
    func setupPlayer() {
        player = SKSpriteNode(imageNamed: "player_idle")
        player.size = CGSize(width: GameConstants.tileSize, height: GameConstants.tileSize)
        player.zPosition = 10
        player.texture?.filteringMode = .nearest
        updatePlayerPosition()
        addChild(player)
    }
    
    func updatePlayerPosition(){
        player.position = CGPoint(
            x: CGFloat(playerGridPos.x) * GameConstants.tileSize + GameConstants.tileSize / 2,
            y: CGFloat(playerGridPos.y) * GameConstants.tileSize + GameConstants.tileSize / 2
        )
    }
    
    func tryMovePlayer(dx: Int, dy: Int){
        let newX = playerGridPos.x + dx
        let newY = playerGridPos.y + dy
        
        guard newY >= 0, newY < GameConstants.gridHeight, newX >= 0, newX < GameConstants.gridWidth else { return }
        guard grid[newY][newX] != .wall else { return }
        
        if let targetEnemy = enemies.first(where: {$0.gridPos == (newX, newY)}){
            attackEnemy(targetEnemy)
        } else {
            playerGridPos = (newX, newY)
            updatePlayerPosition()
        }
        
        processEnemyTurn()
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: tryMovePlayer(dx: -1, dy: 0) // left
        case 124: tryMovePlayer(dx: 1, dy: 0) // right
        case 125: tryMovePlayer(dx: 0, dy: -1) // down
        case 126: tryMovePlayer(dx: 0, dy: 1) // up
        default: break
        }
    }
    
    func spawnEnemies(count: Int = 3){
        var spawned = 0
        var attempts = 0
        
        while spawned < count && attempts < 100 {
            attempts += 1
            let x = Int.random(in: 1..<(GameConstants.gridWidth - 1))
            let y = Int.random(in: 1..<(GameConstants.gridHeight - 1))
            
            guard grid[y][x] == .floor else { continue }
            guard (x, y) != (playerGridPos.x, playerGridPos.y) else { continue }
            guard !enemies.contains(where: { $0.gridPos == (x, y) }) else { continue }
            
            let enemy = Enemy(gridPos: (x, y))
            enemies.append(enemy)
            addChild(enemy.node)
            spawned += 1
        }
    }
    
    func processEnemyTurn(){
        for enemy in enemies {
            let dx = abs(enemy.gridPos.x - playerGridPos.x)
            let dy = abs(enemy.gridPos.y - playerGridPos.y)
            let isAdjacent = (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
            
            if isAdjacent {
                playerHP -= enemy.attackPower
                
                let direction = (dx: playerGridPos.x - enemy.gridPos.x, dy: playerGridPos.y - enemy.gridPos.y)
                applyWithFlash(to: player)
                applyKnockBack(to: player, direction: direction)
                showDamageNumber(enemy.attackPower, at: player.position)
                
                checkPlayerDeath()
                continue
            }
            
            let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
            let move = directions.randomElement()!
            let newX = enemy.gridPos.x + move.0
            let newY = enemy.gridPos.y + move.1
            
            guard newY >= 0, newY < GameConstants.gridHeight, newX >= 0, newX < GameConstants.gridWidth else { continue }
            guard grid[newY][newX] != .wall else { continue }
            guard (newX, newY) != (playerGridPos.x, playerGridPos.y) else { continue }
            guard !enemies.contains(where: { $0 !== enemy && $0.gridPos == (newX, newY) }) else { continue }
            
            enemy.gridPos = (newX, newY)
            enemy.updateNodePosition()
        }
    }
    
    func attackEnemy(_ enemy: Enemy){
        enemy.hp -= playerAttackPower
        
        let direction = (dx: enemy.gridPos.x - playerGridPos.x, dy: enemy.gridPos.y - playerGridPos.y)
        applyWithFlash(to: enemy.node)
        applyKnockBack(to: enemy.node, direction: direction)
        showDamageNumber(playerAttackPower, at: enemy.node.position)
        
        if enemy.hp <= 0 {
            enemy.node.removeFromParent()
            enemies.removeAll { $0 === enemy }
            print("Enemy defeated!")
        }
    }
    
    func checkPlayerDeath(){
        if playerHP <= 0 {
            print("Player died. Game Over")
        }
    }
    
    func applyWithFlash(to node: SKSpriteNode){
        let flashWhite = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.05)
        let flashBack = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        node.run(SKAction.sequence([flashWhite, flashBack]))
    }
    
    func applyKnockBack(to node: SKSpriteNode, direction: (dx: Int, dy: Int)){
        let offset = CGVector(dx: CGFloat(direction.dx) * 8, dy: CGFloat(direction.dy) * 8)
        let knockOut = SKAction.move(by: offset, duration: 0.05)
        let knockBack = SKAction.move(by: CGVector(dx: -offset.dx, dy: -offset.dy), duration: 0.1)
        node.run(SKAction.sequence([knockOut, knockBack]))
    }
    
    func showDamageNumber(_ amount: Int, at position: CGPoint){
        let label = SKLabelNode(text: "\(amount)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 14
        label.fontColor = .red
        label.position = CGPoint(x: position.x, y: position.y + GameConstants.tileSize / 2)
        label.zPosition = 20
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.6)
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove]))
    }
}
