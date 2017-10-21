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
import GameKit

class GameViewController: UIViewController {
	static let gameWidth: Int = 10
	static let gameHeight: Int = 10
	static let initialMineCount: Int = 15
	
	var squareViews: Array<SquareView> = []
	var nonMineSquaresRemaining = 0
	
	func loadGame(newSquareViews: Array<SquareView>, remaining: Int) {
		squareViews.forEach { $0.removeFromSuperview() }
		squareViews = newSquareViews
		nonMineSquaresRemaining = remaining
		for s in squareViews {
			self.view.addSubview(s)
			s.addTarget(self, action: #selector(squareTapped(_:)), for: .primaryActionTriggered)
		}
		refreshSquaresToClear()
	}
	
	func newMineField(mineCount: Int) -> Array<SquareView> {
		let random = GKRandomDistribution(randomSource: GKRandomSource(), lowestValue: 0, highestValue: GameViewController.gameWidth * GameViewController.gameHeight - 1)
		var squares = Array<SquareView>()
		for l in 0..<(GameViewController.gameWidth * GameViewController.gameHeight) {
			squares.append(SquareView(location: l))
		}
		
		for _ in 1...mineCount {
			var n = 0
			repeat {
				n = random.nextInt()
			} while squares[n].isMine
			squares[n].isMine = true
			iterateAdjacent(squareViews: squares, index: n) { (ss: Array<SquareView>, index: Int) in
				if !ss[index].isMine {
					ss[index].adjacent += 1
				}
			}
		}
		return squares
	}
	
	func uncover(squareViews: Array<SquareView>, index: Int) -> Int {
		guard squareViews[index].covering == .covered else { return 0 }
		
		squareViews[index].covering = .uncovered
		squareViews[index].setNeedsDisplay()
		
		if squareViews[index].adjacent == 0 {
			var cleared = 1
			iterateAdjacent(squareViews: squareViews, index: index) { (ss: Array<SquareView>, i: Int) in
				cleared += uncover(squareViews: ss, index: i)
			}
			return cleared
		} else {
			return 1
		}
	}
	
	func iterateAdjacent(squareViews: Array<SquareView>, index n: Int, process: (Array<SquareView>, Int) -> ()) {
		let isOnLeftEdge = n % GameViewController.gameWidth == 0
		let isOnRightEdge = n % GameViewController.gameWidth == GameViewController.gameHeight - 1
		
		if n >= GameViewController.gameWidth {
			if !isOnLeftEdge { process(squareViews, n - GameViewController.gameWidth - 1) }
			process(squareViews, n - GameViewController.gameWidth)
			if !isOnRightEdge { process(squareViews, n - GameViewController.gameWidth + 1) }
		}
		
		if !isOnLeftEdge { process(squareViews, n - 1) }
		if !isOnRightEdge { process(squareViews, n + 1) }
		
		if n < GameViewController.gameWidth * (GameViewController.gameHeight - 1) {
			if !isOnLeftEdge { process(squareViews, n + GameViewController.gameWidth - 1) }
			process(squareViews, n + GameViewController.gameWidth)
			if !isOnRightEdge { process(squareViews, n + GameViewController.gameWidth + 1) }
		}
	}

	@objc func squareTapped(_ sender: Any?) {
		guard let squareView = sender as? SquareView, nonMineSquaresRemaining > 0 else { return }
		
		if flagMode?.isOn == true, squareView.covering != .uncovered {
			squareView.covering = squareView.covering == .covered ? .flagged : .covered
			squareView.setNeedsDisplay()
			return
		} else if squareView.covering == .flagged {
			return
		}
		
		if squareView.isMine {
			squareView.covering = .uncovered
			nonMineSquaresRemaining = -1
			refreshSquaresToClear()
			squareView.setNeedsDisplay()
			return
		}
		
		nonMineSquaresRemaining -= uncover(squareViews: squareViews, index: squareView.location)
		refreshSquaresToClear()
	}
	
	@IBOutlet var squaresToClear: UILabel?
	@IBOutlet var flagMode: UISwitch?
	@IBOutlet var newGameButton: UIButton?
	
	func refreshSquaresToClear() {
		if nonMineSquaresRemaining == -1 {
			squaresToClear?.text = NSLocalizedString("Boom... you lose!", comment: "")
		} else if nonMineSquaresRemaining == 0 {
			squaresToClear?.text = NSLocalizedString("None... you win!", comment: "")
		} else {
			squaresToClear?.text = "\(nonMineSquaresRemaining)"
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		newGameButton?.layer.cornerRadius = 8
		startNewGame()
	}
	
	@IBAction func startNewGame() {
		loadGame(newSquareViews: newMineField(mineCount: GameViewController.initialMineCount), remaining: GameViewController.gameWidth * GameViewController.gameHeight - GameViewController.initialMineCount)
	}
	
	override func viewDidLayoutSubviews() {
		let availableWidth = self.view.frame.size.width
		let usedWidth = CGFloat(SquareView.squareSize + 2) * CGFloat(GameViewController.gameWidth)
		let availableHeight = self.view.frame.size.height
		let usedHeight = CGFloat(SquareView.squareSize + 2) * CGFloat(GameViewController.gameHeight)
		
		for sv in squareViews {
			let x = sv.location % GameViewController.gameWidth
			let y = sv.location / GameViewController.gameWidth
			
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
		
		if let squaresArray = coder.decodeObject(forKey: String.squaresKey) as? Array<Dictionary<String, Any>>, coder.containsValue(forKey: String.remainingKey) {
			do {
				let newSquareViews = try squaresArray.map { try SquareView(fromDictionary: $0) }
				loadGame(newSquareViews: newSquareViews, remaining: coder.decodeInteger(forKey: String.remainingKey))
			} catch {
				startNewGame()
			}
		}
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode(squareViews.map { $0.toDictionary() } as Array<Dictionary<String, Any>>, forKey: String.squaresKey)
		coder.encode(nonMineSquaresRemaining as Int, forKey: String.remainingKey)
		coder.encode((flagMode?.isOn == true) as Bool, forKey: String.flagModeKey)
	}
}

fileprivate extension String {
	static let squaresKey = "squares"
	static let remainingKey = "remaining"
	static let flagModeKey = "flagMode"
}
