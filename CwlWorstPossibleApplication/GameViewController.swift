//
//  GameViewController.swift
//  CwlWorstPossibleApplication
//
//  Created by Matt Gallagher on 2017/09/01.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
	@IBOutlet var squaresToClear: UILabel?
	@IBOutlet var flagMode: UISwitch?
	@IBOutlet var newGameButton: UIButton?
	
	var game = Game() { didSet {
		NotificationCenter.default.removeObserver(self, name: Game.changed, object: oldValue)
		NotificationCenter.default.addObserver(self, selector: #selector(gameChanged(_:)), name: Game.changed, object: game)
		NotificationCenter.default.post(name: Game.changed, object: game)
	} }
	
	var squareViews: Array<SquareView> = []
	
	@objc func gameChanged(_ notification: Notification) {
		if let userInfo = notification.userInfo, let changedSquare = userInfo[Game.squareIndexKey] as? Int {
			squareViews[changedSquare].setNeedsDisplay()
		} else {
			squareViews.forEach { $0.setNeedsDisplay() }
		}

		if game.nonMineSquaresRemaining == -1 {
			squaresToClear?.text = NSLocalizedString("Boom... you lose!", comment: "")
		} else if game.nonMineSquaresRemaining == 0 {
			squaresToClear?.text = NSLocalizedString("None... you win!", comment: "")
		} else {
			squaresToClear?.text = "\(game.nonMineSquaresRemaining)"
		}
	}
	
	@IBAction func startNewGame() {
		game = Game()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		newGameButton?.layer.cornerRadius = 8
		
		squareViews.reserveCapacity(game.squares.count)
		for s in game.squares {
			let sv = SquareView(square: s)
			squareViews.append(sv)
			self.view.addSubview(sv)
			sv.addTarget(self, action: #selector(squareTapped(_:)), for: .primaryActionTriggered)
		}
	}
	
	@objc func squareTapped(_ sender: Any?) {
		guard let s = sender as? SquareView else { return }
		game.tapSquare(index: s.square.location, flagMode: flagMode?.isOn ?? false)
	}
	
	override func viewDidLayoutSubviews() {
		let availableWidth = self.view.frame.size.width
		let usedWidth = CGFloat(SquareView.squareSize + 2) * CGFloat(Game.gameWidth)
		let availableHeight = self.view.frame.size.height
		let usedHeight = CGFloat(SquareView.squareSize + 2) * CGFloat(Game.gameHeight)
		
		for sv in squareViews {
			let x = sv.square.location % Game.gameWidth
			let y = sv.square.location / Game.gameWidth

			sv.frame.origin = CGPoint(x: 0.5 * (availableWidth - usedWidth) + CGFloat(x) * CGFloat(SquareView.squareSize + 2) + 1, y: 0.5 * (availableHeight - usedHeight) + CGFloat(y) * CGFloat(SquareView.squareSize + 2) + 1)
		}
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		if coder.containsValue(forKey: String.remainingKey) {
			flagMode?.isOn = coder.decodeBool(forKey: String.flagModeKey)
		}
		
		if let squaresArray = coder.decodeObject(forKey: String.squaresKey) as? Array<Dictionary<String, Any>>, coder.containsValue(forKey: String.remainingKey) {
			do {
				let newSquares = try squaresArray.map { try SquareView(fromDictionary: $0) }
				loadGame(newSquares: newSquares, remaining: coder.decodeInteger(forKey: String.remainingKey))
			} catch {
				startNewGame()
			}
		}
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode(squares.map { $0.toDictionary() } as Array<Dictionary<String, Any>>, forKey: String.squaresKey)
		coder.encode(nonMineSquaresRemaining as Int, forKey: String.remainingKey)
		coder.encode((flagMode?.isOn == true) as Bool, forKey: String.flagModeKey)
	}
}

fileprivate extension String {
	static let flagModeKey = "flagMode"
}

