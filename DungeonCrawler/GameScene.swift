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
    
    var comboCount = 0
    
    var isGameOver = false
    
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
        guard !isGameOver else { return }
        
        let newX = playerGridPos.x + dx
        let newY = playerGridPos.y + dy
        
        guard newY >= 0, newY < GameConstants.gridHeight, newX >= 0, newX < GameConstants.gridWidth else { return }
        guard grid[newY][newX] != .wall else { return }
        
        if let targetEnemy = enemies.first(where: {$0.gridPos == (newX, newY)}){
            attackEnemy(targetEnemy)
        } else {
            playerGridPos = (newX, newY)
            updatePlayerPosition()
            player.run(makeWalkAnimation(imageName: "player_walk", frameCount: 4))
            run(SKAction.playSoundFileNamed("step.wav", waitForCompletion: false))
        }
        
        processEnemyTurn()
    }
    
    override func keyDown(with event: NSEvent) {
        if isGameOver {
            if event.keyCode == 15 {
                restartGame()
            }
            return
        }
        
        switch event.keyCode {
        case 123: tryMovePlayer(dx: -1, dy: 0) // left
        case 124: tryMovePlayer(dx: 1, dy: 0) // right
        case 125: tryMovePlayer(dx: 0, dy: -1) // down
        case 126: tryMovePlayer(dx: 0, dy: 1) // up
        default: break
        }
    }
    
    func restartGame(){
        removeAllChildren()
        isGameOver = false
        playerHP = 10
        comboCount = 0
        enemies = []
        
        let generator = DungeonGenerator(width: GameConstants.gridWidth, height: GameConstants.gridHeight)
        grid = generator.generate()
        playerGridPos = (x: GameConstants.gridWidth / 2, y: GameConstants.gridHeight / 2)
        
        renderGrid()
        setupPlayer()
        spawnEnemies()
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
            
            let type = EnemyType.allCases.randomElement()!
            let enemy = Enemy(gridPos: (x, y), type: type)
            enemies.append(enemy)
            addChild(enemy.node)
            spawned += 1
        }
    }
    
    func processEnemyTurn(){
        let pathfinder = Pathfinder(grid: grid, width: GameConstants.gridWidth, height: GameConstants.gridHeight)
        
        for enemy in enemies {
            let dx = abs(enemy.gridPos.x - playerGridPos.x)
            let dy = abs(enemy.gridPos.y - playerGridPos.y)
            let distance = dx + dy
            let isAdjacent = (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
            let isLowHP = enemy.hp <= enemy.maxHP / 3
            
            if isAdjacent && !(enemy.type == .coward && isLowHP) {
                playerHP -= enemy.attackPower
                comboCount = 0
                let direction = (dx: playerGridPos.x - enemy.gridPos.x, dy: playerGridPos.y - enemy.gridPos.y)
                applyWithFlash(to: player)
                applyKnockBack(to: player, direction: direction)
                showDamageNumber(enemy.attackPower, at: player.position)
                checkPlayerDeath()
                continue
            }
            
            guard distance <= enemy.detectionRadius else { continue }
            
            var step: (dx: Int, dy: Int)?
            
            switch enemy.type {
            case .chaser:
                step = pathfinder.nextStep(from: enemy.gridPos, to: playerGridPos)
            case .guardian:
                step = nil
            case .coward:
                if isLowHP {
                    step = fleeDirection(from: enemy.gridPos, awayFrom: playerGridPos)
                } else {
                    step = pathfinder.nextStep(from: enemy.gridPos, to: playerGridPos)
                }
            }
            
            guard let move = step else { continue }
            let newX = enemy.gridPos.x + move.dx
            let newY = enemy.gridPos.y + move.dy
            
            guard newX >= 0, newX < GameConstants.gridWidth, newY >= 0, newY < GameConstants.gridHeight else { continue }
            guard grid[newY][newX] != .wall else { continue }
            guard !enemies.contains(where: { $0 !== enemy && $0.gridPos == (newX, newY) }) else { continue }
            
            enemy.gridPos = (newX, newY)
            enemy.updateNodePosition()
            enemy.node.run(makeWalkAnimation(imageName: enemy.type.walkAnimationName, frameCount: 4))
        }
    }
    
    func fleeDirection(from pos: (x: Int, y: Int), awayFrom target: (x: Int, y: Int)) -> (dx: Int, dy: Int)? {
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        var bestDir: (Int, Int)?
        var bestDistance = -1
        
        for dir in directions {
            let next = (x: pos.x + dir.0, y: pos.y + dir.1)
            guard next.x >= 0, next.x < GameConstants.gridWidth, next.y >= 0, next.y < GameConstants.gridHeight else { continue }
            guard grid[next.y][next.x] != .wall else { continue }
            
            let dist = abs(next.x - target.x) + abs(next.y - target.y)
            if dist > bestDistance {
                bestDistance = dist
                bestDir = dir
            }
        }
        
        guard let dir = bestDir else { return nil }
        return (dx: dir.0, dy: dir.1)
    }
    
    func attackEnemy(_ enemy: Enemy){
        run(SKAction.playSoundFileNamed("attack.wav", waitForCompletion: false))
        
        let isCrit = Double.random(in: 0...1) < GameConstants.critChance
        let damage = isCrit ? playerAttackPower * GameConstants.critMultiplier : playerAttackPower
        enemy.hp -= damage
        
        let direction = (dx: enemy.gridPos.x - playerGridPos.x, dy: enemy.gridPos.y - playerGridPos.y)
        applyWithFlash(to: enemy.node)
        applyKnockBack(to: enemy.node, direction: direction)
        
        if isCrit {
            showCritDamageNumber(playerAttackPower, at: enemy.node.position)
        } else {
            showDamageNumber(playerAttackPower, at: enemy.node.position)
        }
        
        if enemy.hp <= 0 {
            let deathPosition = enemy.node.position
            enemy.node.removeFromParent()
            enemies.removeAll { $0 === enemy }
            shakeScreen(intensity: 8, duration: 0.15)
            spawnDeathParticles(at: deathPosition)
            run(SKAction.playSoundFileNamed("enemy_death.wav", waitForCompletion: false))
            
            comboCount += 1
            showComboText()
        }
    }
    
    func checkPlayerDeath(){
        if playerHP <= 0 && !isGameOver {
            isGameOver = true
            print("Player died. Game Over")
            showGameOverText()
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
    
    func showCritDamageNumber(_ amount: Int, at position: CGPoint){
        let label = SKLabelNode(text: "\(amount)!")
        label.fontName = "Menlo-Bold"
        label.fontSize = 22
        label.fontColor = .systemOrange
        label.position = CGPoint(x: position.x, y: position.y + GameConstants.tileSize / 2)
        label.zPosition = 20
        addChild(label)
        
        let scaleIn = SKAction.scale(to: 1.4, duration: 0.08)
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 25, duration: 0.6)
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([
            SKAction.sequence([scaleIn, scaleBack]),
            SKAction.group([moveUp, fadeOut]),
            remove
        ]))
    }
    
    func makeWalkAnimation(imageName: String, frameCount: Int) -> SKAction{
        let sheet = SKTexture(imageNamed: imageName)
        var textures: [SKTexture] = []
        
        let frameWidth = 1.0 / CGFloat(frameCount)
        for i in 0..<frameCount {
            let rect = CGRect(x: CGFloat(i) * frameWidth, y: 0, width: frameWidth, height: 1.0)
            let frameTexture = SKTexture(rect: rect, in: sheet)
            frameTexture.filteringMode = .nearest
            textures.append(frameTexture)
        }
        
        return SKAction.animate(with: textures, timePerFrame: 0.15)
    }
    
    func shakeScreen(intensity: CGFloat = 6, duration: TimeInterval = 0.2){
        guard let cam = camera else {
            let originalPosition = position
            var actions: [SKAction] = []
            let steps = 6
            for _ in 0..<steps {
                let dx = CGFloat.random(in: -intensity...intensity)
                let dy = CGFloat.random(in: -intensity...intensity)
                actions.append(SKAction.move(by: CGVector(dx: dx, dy: dy), duration: duration / Double(steps)))
            }
            actions.append(SKAction.move(to: originalPosition, duration: duration / Double(steps)))
            run(SKAction.sequence(actions))
            return
        }
        let originalPosition = cam.position
        var actions: [SKAction] = []
        let steps = 6
        for _ in 0..<steps{
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(SKAction.move(by: CGVector(dx: dx, dy: dy), duration: duration / Double(steps)))
        }
        actions.append(SKAction.move(to: originalPosition, duration: duration / Double(steps)))
        cam.run(SKAction.sequence(actions))
    }
    
    func spawnDeathParticles(at position: CGPoint, color: NSColor = .systemGreen) {
        for _ in 0..<8{
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 15
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 15...30)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            
            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            particle.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
        }
    }
    
    func showComboText(){
        guard comboCount >= 2 else { return }
        
        let label = SKLabelNode(text: "\(comboCount)x COMBO!")
        label.fontName = "Menlo-Bold"
        label.fontSize = 16
        label.color = .systemYellow
        label.position = CGPoint(x: player.position.x, y: player.position.y + GameConstants.tileSize)
        label.zPosition = 20
        addChild(label)
        
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 25, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([
            SKAction.sequence([scaleUp, scaleDown]),
            SKAction.group([moveUp, fadeOut]),
            remove
        ]))
    }
    
    func showGameOverText() {
        let title = SKLabelNode(text: "GAME OVER")
        title.fontName = "Menlo-Bold"
        title.fontSize = 22
        title.fontColor = .systemRed
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 12)
        title.zPosition = 30
        addChild(title)

        let subtitle = SKLabelNode(text: "Press R to Restart")
        subtitle.fontName = "Menlo"
        subtitle.fontSize = 12
        subtitle.fontColor = .white
        subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 - 12)
        subtitle.zPosition = 30
        addChild(subtitle)
    }
}
