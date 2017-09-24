//
//  SquareView.swift
//  CwlWorstPossibleApplication
//
//  Created by Matt Gallagher on 2017/09/20.
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

class SquareView: UIButton {
	static let font = UIFont.systemFont(ofSize: 18)
	static let squareSize: CGFloat = 30
	static let textPadding: CGFloat = 2
	
	enum Covering: String {
		case uncovered = "uncovered"
		case covered = "covered"
		case flagged = "flagged"
	}

	var covering: Covering = .covered { didSet { setNeedsDisplay() } }
	var isMine: Bool = false
	var adjacent: Int8 = 0
	var location: Int
	
	init(location: Int) {
		self.location = location
		super.init(frame: CGRect(x: 0, y: 0, width: SquareView.squareSize, height: SquareView.squareSize))
	}
	
	init(fromDictionary dictionary: Dictionary<String, Any>) throws {
		if let coveringString = dictionary[String.coveringKey] as? String, let covering = SquareView.Covering(rawValue: coveringString), let location = dictionary[String.locationKey] as? Int, let adjacent = dictionary[String.adjacentKey] as? Int8, let isMine = dictionary[String.isMineKey] as? Bool {
			self.adjacent = adjacent
			self.covering = covering
			self.isMine = isMine
			self.location = location
			super.init(frame: CGRect(x: 0, y: 0, width: SquareView.squareSize, height: SquareView.squareSize))
		} else {
			throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.coderValueNotFound.rawValue, userInfo: nil)
		}
	}
	
	required init(coder: NSCoder) { fatalError() }
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath(rect: rect)
		if covering == .uncovered {
			UIColor(red: 0.8, green: 0.68, blue: 0.6, alpha: 1).set()
		} else {
			UIColor(red: 0.472, green: 0.333, blue: 0.277, alpha: 1).set()
		}
		path.fill()
		
		if covering != .covered {
			let alignCenter = NSMutableParagraphStyle()
			alignCenter.alignment = .center
			alignCenter.minimumLineHeight = SquareView.squareSize - 2 * SquareView.textPadding
			let string: String
			if covering == .flagged {
				string = "⚑"
			} else if isMine {
				string = "💣"
			} else if adjacent != 0 {
				string = "\(adjacent)"
			} else {
				string = ""
			}
			NSAttributedString(string: string, attributes: [.paragraphStyle: alignCenter, .font: SquareView.font]).draw(in: rect)
		}
	}
	
	func toDictionary() -> Dictionary<String, Any> {
		return [String.coveringKey: covering.rawValue, String.isMineKey: isMine, String.adjacentKey: adjacent, String.locationKey: location]
	}
}

fileprivate extension String {
	static let coveringKey = "covering"
	static let isMineKey = "isMine"
	static let adjacentKey = "adjacent"
	static let locationKey = "location"
}
