//
//  ViewController.swift
//  DungeonCrawler
//
//  Created by habil on 11/07/26.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            let sceneSize = CGSize(
                width: CGFloat(GameConstants.gridWidth) * GameConstants.tileSize,
                height: CGFloat(GameConstants.gridHeight) * GameConstants.tileSize
            )
            let scene = GameScene(size: sceneSize)
            scene.scaleMode = .aspectFit
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
}

