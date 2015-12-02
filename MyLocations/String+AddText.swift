//
//  String+AddText.swift
//  MyLocations
//
//  Created by Molly Waggett on 12/2/15.
//  Copyright © 2015 Molly Waggett. All rights reserved.
//

extension String {
  mutating func addText(text: String?, withSeparator separator: String = "") {
    if let text = text {
      if !isEmpty {
        self += separator
      }
      self += text
    }
  }
}
