//
//  GameViewController.swift
//  CwlWorstPossibleApplication
//
//  Created by Matt Gallagher on 2017/09/01.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

import UIKit

class GameViewController: UIViewController {
	@IBOutlet var squaresToClear: UILabel?
	@IBOutlet var flagMode: UISwitch?
	@IBOutlet var newGameButton: UIButton?
	
	var game = Game() { didSet {
		updateObserving(oldGame: oldValue, newGame: game)
	} }
	
	var squareViews: Array<SquareView> = []
	
	func updateObserving(oldGame: Game?, newGame: Game) {
		if let old = oldGame {
			NotificationCenter.default.removeObserver(self, name: Game.changed, object: old)
		}
		NotificationCenter.default.addObserver(self, selector: #selector(gameChanged(_:)), name: Game.changed, object: newGame)
		gameChanged(Notification(name: Game.changed))
	}
	
	@objc func gameChanged(_ notification: Notification) {
		if let userInfo = notification.userInfo, let newSquare = userInfo[Game.squareKey] as? Square {
			squareViews[newSquare.location].square = newSquare
		} else {
			for s in game.squares {
				squareViews[s.location].square = s
			}
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
	
	@objc func squareTapped(_ sender: Any?) {
		guard let s = sender as? SquareView else { return }
		game.tapSquare(index: s.square.location, flagMode: flagMode?.isOn ?? false)
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
		
		updateObserving(oldGame: nil, newGame: game)
	}
	
	override func viewDidLayoutSubviews() {
		let availableWidth = self.view.frame.size.width
		let usedWidth = CGFloat(SquareView.squareSize + 2) * CGFloat(Game.gameWidth)
		let availableHeight = self.view.frame.size.height
		let usedHeight = CGFloat(SquareView.squareSize + 2) * CGFloat(Game.gameHeight)
		
		for sv in squareViews {
			let x = sv.square.location % Game.gameWidth
			let y = sv.square.location / Game.gameWidth

			let size = CGFloat(SquareView.squareSize + 2)
			let xCoord = 0.5 * (availableWidth - usedWidth) + CGFloat(x) * size + 1
			let yCoord = 0.5 * (availableHeight - usedHeight) + CGFloat(y) * size + 1
			sv.frame.origin = CGPoint(x: xCoord, y: yCoord)
		}
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		if coder.containsValue(forKey: String.flagModeKey) {
			flagMode?.isOn = coder.decodeBool(forKey: String.flagModeKey)
		}
		
		if let data = coder.decodeObject(forKey: String.gameKey) as? Data, let restored = try? JSONDecoder().decode(Game.self, from: data) {
			game = restored
		}
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode((flagMode?.isOn == true) as Bool, forKey: String.flagModeKey)
		if let data = try? JSONEncoder().encode(game) {
			_ = coder.encode(data, forKey: String.gameKey)
		}
	}
}

fileprivate extension String {
	static let flagModeKey = "flagMode"
	static let gameKey = "game"
}

