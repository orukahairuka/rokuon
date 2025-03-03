//
//  GameScene.swift
//  rokuon
//
//  Created by 櫻井絵理香 on 2025/03/03.
//

import Foundation
import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private var player: SKSpriteNode!
    private var ground: SKSpriteNode!
    private var background1: SKSpriteNode!
    private var background2: SKSpriteNode!

    private enum PlayerStatus {
        case idle
        case prepareJump
        case jumping
        case landed
    }

    private var status: PlayerStatus = .idle

    private let jumpTexture = SKTexture(imageNamed: "j1")
    private let runTexture = SKTexture(imageNamed: "r1")

    private let enemyTexture = SKTexture(imageNamed: "enemy")
    private var enemySpawnYRange: ClosedRange<CGFloat> = 50...150 // 敵の出現位置（Y座標）
    private var enemySpawnXRange: ClosedRange<CGFloat> = 50...100 // 敵の出現位置（X軸の移動距離）
    private var enemySpawnInterval: TimeInterval = 2.0 // 敵の出現間隔

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)

        setupScrollingBackground()
        setupGround()
        setupPlayer()
        spawnEnemies()
    }

    private func setupScrollingBackground() {
        background1 = SKSpriteNode(imageNamed: "background")
        background1.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background1.zPosition = -1
        background1.size = self.size
        addChild(background1)

        background2 = SKSpriteNode(imageNamed: "background")
        background2.position = CGPoint(x: size.width + size.width / 2, y: size.height / 2)
        background2.zPosition = -1
        background2.size = self.size
        addChild(background2)

        let moveLeft = SKAction.moveBy(x: -size.width, y: 0, duration: 3)
        let resetPosition = SKAction.moveBy(x: size.width, y: 0, duration: 0)
        let loop = SKAction.repeatForever(SKAction.sequence([moveLeft, resetPosition]))

        background1.run(loop)
        background2.run(loop)
    }

    private func setupGround() {
        ground = SKSpriteNode(color: .brown, size: CGSize(width: size.width, height: 50))
        ground.position = CGPoint(x: size.width / 2, y: 25)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 0x1 << 1
        ground.physicsBody?.collisionBitMask = 0x1 << 0
        addChild(ground)
    }

    private func setupPlayer() {
        player = SKSpriteNode(texture: runTexture)
        player.size = CGSize(width: 50, height: 50)
        player.position = CGPoint(x: size.width * 0.2, y: size.height * 0.3)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = 0x1 << 0
        player.physicsBody?.collisionBitMask = 0x1 << 1
        player.physicsBody?.contactTestBitMask = 0x1 << 2
        player.physicsBody?.affectedByGravity = true
        addChild(player)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let physicsBody = player?.physicsBody else { return }

        if status == .jumping || status == .prepareJump {
            return
        }

        status = .prepareJump
        player.texture = jumpTexture
        physicsBody.applyImpulse(CGVector(dx: 0, dy: 60))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.status = .jumping
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if status == .jumping {
            if let velocity = player.physicsBody?.velocity.dy, velocity <= 0 {
                status = .idle
                player.texture = runTexture
            }
        }
    }

    private func spawnEnemies() {
        let createEnemy = SKAction.run {
            let enemy = SKSpriteNode(texture: self.enemyTexture)
            enemy.size = CGSize(width: 40, height: 40)
            let randomY = CGFloat.random(in: self.enemySpawnYRange)
            let randomXOffset = CGFloat.random(in: self.enemySpawnXRange)
            enemy.position = CGPoint(x: self.size.width + randomXOffset, y: randomY)
            enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
            enemy.physicsBody?.isDynamic = false
            enemy.physicsBody?.categoryBitMask = 0x1 << 2
            enemy.physicsBody?.collisionBitMask = 0
            enemy.physicsBody?.contactTestBitMask = self.player.physicsBody!.categoryBitMask

            let moveLeft = SKAction.moveBy(x: -self.size.width - randomXOffset, y: 0, duration: 3.0)
            let remove = SKAction.removeFromParent()
            enemy.run(SKAction.sequence([moveLeft, remove]))

            self.addChild(enemy)
        }

        let wait = SKAction.wait(forDuration: enemySpawnInterval)
        let sequence = SKAction.sequence([createEnemy, wait])
        run(SKAction.repeatForever(sequence))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        gameOver()
    }

    private func gameOver() {
        print("Game Over")

        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameOverLabel)

        self.isPaused = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = .aspectFill
            self.view?.presentScene(newScene)
        }
    }
}
