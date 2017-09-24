//
//  SquareView.swift
//  CwlWorstPossibleApplication
//
//  Created by Matt Gallagher on 2017/09/20.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

class SquareView: UIButton {
	static let font = UIFont.systemFont(ofSize: 18)
	static let squareSize: CGFloat = 30
	static let textPadding: CGFloat = 2
	static let paragraphStyle: NSParagraphStyle = {
		let alignCenter = NSMutableParagraphStyle()
		alignCenter.alignment = .center
		alignCenter.minimumLineHeight = SquareView.squareSize - 2 * SquareView.textPadding
		return alignCenter
	}()
	
	var square: Square { didSet { setNeedsDisplay() } }
	init(square: Square) {
		self.square = square
		super.init(frame: CGRect(x: 0, y: 0, width: SquareView.squareSize, height: SquareView.squareSize))
	}
	required init(coder: NSCoder) { fatalError() }
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath(rect: rect)
		if square.covering != .uncovered {
			UIColor(red: 0.472, green: 0.333, blue: 0.277, alpha: 1).set()
		} else {
			UIColor(red: 0.8, green: 0.68, blue: 0.6, alpha: 1).set()
		}
		path.fill()
		
		let string: String
		if square.covering == .covered {
			return
		} else if square.covering == .flagged {
			string = "⚑"
		} else if square.isMine {
			string = "💣"
		} else if square.adjacent != 0 {
			string = "\(square.adjacent)"
		} else {
			return
		}
		NSAttributedString(string: string, attributes: [.paragraphStyle: SquareView.paragraphStyle, .font: SquareView.font]).draw(in: rect)
	}
}

