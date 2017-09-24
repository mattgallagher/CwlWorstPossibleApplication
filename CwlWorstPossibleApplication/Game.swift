//
//  Game.swift
//  CwlWorstPossibleApplication
//
//  Created by Matt Gallagher on 2017/09/24.
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

import Foundation
import GameKit

struct Square: Codable {
	enum Covering: String, Codable {
		case uncovered = "uncovered"
		case covered = "covered"
		case flagged = "flagged"
	}
	
	var covering: Covering = .covered
	var isMine: Bool = false
	var adjacent: Int8 = 0
	var location: Int
	
	init(location: Int) {
		self.location = location
	}
}

class Game: Codable {
	static let changed = Notification.Name("gameChanged")
	static let squareKey = "square"
	
	static let gameWidth: Int = 10
	static let gameHeight: Int = 10
	static let initialMineCount: Int = 15
	
	private(set) var squares: Array<Square>
	private(set) var nonMineSquaresRemaining: Int
	
	init() {
		let totalSquares = Game.gameWidth * Game.gameHeight
		nonMineSquaresRemaining = totalSquares - Game.initialMineCount
		squares = Array<Square>()
		squares.reserveCapacity(totalSquares)
		for l in 0..<(Game.gameWidth * Game.gameHeight) {
			squares.append(Square(location: l))
		}
		
		let random = GKRandomDistribution(randomSource: GKRandomSource(), lowestValue: 0, highestValue: Game.gameWidth * Game.gameHeight - 1)
		for _ in 1...Game.initialMineCount {
			var n = 0
			repeat {
				n = random.nextInt()
			} while squares[n].isMine
			squares[n].isMine = true
			iterateAdjacent(squares: &squares, index: n) { (ss: inout Array<Square>, index: Int) in
				if !ss[index].isMine {
					ss[index].adjacent += 1
				}
			}
		}
	}
	
	private func notifySquareChanged(_ square: Square) {
		NotificationCenter.default.post(name: Game.changed, object: self, userInfo: [Game.squareKey: square])
	}
	
	func tapSquare(index: Int, flagMode: Bool) {
		guard nonMineSquaresRemaining > 0 else { return }
		
		if flagMode, squares[index].covering != .uncovered {
			squares[index].covering = squares[index].covering == .covered ? .flagged : .covered
			notifySquareChanged(squares[index])
			return
		} else if squares[index].covering == .flagged {
			return
		}
		
		if squares[index].isMine {
			squares[index].covering = .uncovered
			nonMineSquaresRemaining = -1
			notifySquareChanged(squares[index])
			return
		}
		
		uncover(squares: &squares, index: squares[index].location)
	}

	private func uncover(squares: inout Array<Square>, index: Int) {
		guard squares[index].covering == .covered else { return }
		
		squares[index].covering = .uncovered
		nonMineSquaresRemaining -= 1
		notifySquareChanged(squares[index])
		
		if squares[index].adjacent == 0 {
			iterateAdjacent(squares: &squares, index: index) { (ss: inout Array<Square>, i: Int) in
				uncover(squares: &ss, index: i)
			}
		}
	}
	
	private func iterateAdjacent(squares: inout Array<Square>, index n: Int, process: (inout Array<Square>, Int) -> ()) {
		let isOnLeftEdge = n % Game.gameWidth == 0
		let isOnRightEdge = n % Game.gameWidth == Game.gameHeight - 1
		
		if n >= Game.gameWidth {
			if !isOnLeftEdge { process(&squares, n - Game.gameWidth - 1) }
			process(&squares, n - Game.gameWidth)
			if !isOnRightEdge { process(&squares, n - Game.gameWidth + 1) }
		}
		
		if !isOnLeftEdge { process(&squares, n - 1) }
		if !isOnRightEdge { process(&squares, n + 1) }
		
		if n < Game.gameWidth * (Game.gameHeight - 1) {
			if !isOnLeftEdge { process(&squares, n + Game.gameWidth - 1) }
			process(&squares, n + Game.gameWidth)
			if !isOnRightEdge { process(&squares, n + Game.gameWidth + 1) }
		}
	}
}
