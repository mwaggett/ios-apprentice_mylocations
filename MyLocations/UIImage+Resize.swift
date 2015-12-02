//
//  UIImage+Resize.swift
//  MyLocations
//
//  Created by Molly Waggett on 12/2/15.
//  Copyright © 2015 Molly Waggett. All rights reserved.
//

import UIKit


extension UIImage {
  func resizedImageWithBounds(bounds: CGSize) -> UIImage {
    let horitzontalRatio = bounds.width / size.width
    let verticalRatio = bounds.height / size.height
    let ratio = min(horitzontalRatio, verticalRatio)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
    drawInRect(CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
  }
}