//
//  RootActionableItem.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/27.
//

import Foundation
import RxSwift
import Combine

public protocol RootActionableItem: AnyObject {
  func waitForLogin() -> AnyPublisher<(LoggedInActionableItem, ()), Error>
}
