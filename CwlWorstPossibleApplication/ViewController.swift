//
//  ViewController.swift
//  CwlWorstPossibleApplication
//
//  Created by Matt Gallagher on 2017/09/01.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit
import GameKit

let squareSize = 30
let gameWidth: Int = 10
let gameHeight: Int = 10
let initialMineCount: Int = 20

enum Covering { case uncovered, covered, flagged }
class Square: UIButton {
	var covering: Covering = .covered
	var isMine: Bool = false
	var adjacent: Int8 = 0
	var location: Int
	init(location: Int) {
		self.location = location
		super.init(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
	}
	required init(coder: NSCoder) {
		fatalError()
	}
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath(rect: rect)
		if covering == .uncovered {
			UIColor.lightGray.set()
		} else {
			UIColor.gray.set()
		}
		path.fill()
		
		if covering == .uncovered {
			let alignCenter = NSMutableParagraphStyle()
			alignCenter.alignment = .center
			alignCenter.minimumLineHeight = CGFloat(squareSize - 4)
			let font = UIFont.systemFont(ofSize: 18)
			if isMine {
				NSAttributedString(string: "💣", attributes: [.paragraphStyle: alignCenter, .font: font]).draw(in: rect)
			} else if adjacent != 0 {
				NSAttributedString(string: "\(adjacent)", attributes: [.paragraphStyle: alignCenter, .font: font]).draw(in: rect)
			}
		}
	}
}

class ViewController: UIViewController {
	
	var squares: Array<Square> = {
		let random = GKRandomDistribution(randomSource: GKRandomSource(), lowestValue: 0, highestValue: gameWidth * gameHeight - 1)
		var squares = Array<Square>()
		for l in 0..<(gameWidth * gameHeight) {
			squares.append(Square(location: l))
		}
		
		for _ in 1...initialMineCount {
			var n = 0
			repeat {
				n = random.nextInt()
			} while squares[n].isMine
			squares[n].isMine = true
			iterateAdjacent(squares: &squares, n: n) { (s: inout Square) in if !s.isMine { s.adjacent += 1 } }
		}
		return squares
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		for s in squares {
			self.view.addSubview(s)
			s.addTarget(self, action: #selector(squareTapped(_:)), for: .primaryActionTriggered)
		}
	}
	
	@objc func squareTapped(_ sender: Any?) {
		guard let s = sender as? Square else { return }
		s.covering = .uncovered
		s.setNeedsDisplay()
	}
	
	override func viewDidLayoutSubviews() {
		let availableWidth = self.view.frame.size.width
		let usedWidth = CGFloat(squareSize + 2) * CGFloat(gameWidth)
		let availableHeight = self.view.frame.size.height
		let usedHeight = CGFloat(squareSize + 2) * CGFloat(gameHeight)
		for y in 0..<gameHeight {
			for x in 0..<gameWidth {
				let s = squares[x + y * gameWidth]
				s.frame.origin = CGPoint(x: 0.5 * (availableWidth - usedWidth) + CGFloat(x) * CGFloat(squareSize + 2), y: 0.5 * (availableHeight - usedHeight) + CGFloat(y) * CGFloat(squareSize + 2))
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
}

func iterateAdjacent(squares: inout Array<Square>, n: Int, process: (inout Square) -> ()) {
	let touchesLeft = n % gameWidth == 0
	let touchesRight = n % gameWidth == gameHeight - 1
	if n >= gameWidth {
		if !touchesLeft { process(&squares[n - gameWidth - 1]) }
		process(&squares[n - gameWidth])
		if !touchesRight { process(&squares[n - gameWidth + 1]) }
	}
	if !touchesLeft { process(&squares[n - 1]) }
	process(&squares[n])
	if !touchesRight { process(&squares[n + 1]) }
	if n < gameWidth * (gameHeight - 1) {
		if !touchesLeft { process(&squares[n + gameWidth - 1]) }
		process(&squares[n + gameWidth])
		if !touchesRight { process(&squares[n + gameWidth + 1]) }
	}
}
