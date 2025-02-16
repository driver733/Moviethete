//
//  FloatRule.swift
//  Validator
//
//  Created by Cameron McCord on 5/5/15.
//  Copyright (c) 2015 jpotts18. All rights reserved.
//

import Foundation

public class FloatRule:Rule {
    
    private var message : String

    public init(message : String = "This must be a number with or without a decimal"){
        self.message = message
    }
    
    public func validate(value: String) -> Bool {
      do {
        let regex = try NSRegularExpression(pattern: ("[-+]?(\\d*[.])?\\d+" as? String)!, options: NSRegularExpressionOptions.AllowCommentsAndWhitespace)
            let match = regex.numberOfMatchesInString(value, options: NSMatchingOptions.Anchored, range: NSRange(location: 0, length: value.characters.count))
            return match == 1
        return false
      }
      catch {
      
      }
      return false
    }
    
    public func errorMessage() -> String {
        return message
    }
}