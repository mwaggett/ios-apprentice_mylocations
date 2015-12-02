//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Molly Waggett on 12/2/15.
//  Copyright © 2015 Molly Waggett. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
  
  override func childViewControllerForStatusBarStyle() -> UIViewController? {
    return nil
  }
}