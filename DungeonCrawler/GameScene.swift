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
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let generator = DungeonGenerator(width: GameConstants.gridWidth, height: GameConstants.gridHeight)
        grid = generator.generate()
        renderGrid()
        setupPlayer()
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
                let color: NSColor = (tile == .wall) ? .darkGray : .lightGray
                
                let node = SKSpriteNode(color: color, size: CGSize(width: GameConstants.tileSize, height: GameConstants.tileSize))
                node.position = CGPoint(
                    x: CGFloat(x) * GameConstants.tileSize + GameConstants.tileSize / 2,
                    y: CGFloat(y) * GameConstants.tileSize + GameConstants.tileSize / 2
                )
                addChild(node)
            }
        }
    }
    
    func setupPlayer() {
        player = SKSpriteNode(color: .systemRed, size: CGSize(width: GameConstants.tileSize - 4, height: GameConstants.tileSize - 4))
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
        
        playerGridPos = (newX, newY)
        updatePlayerPosition()
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
}
