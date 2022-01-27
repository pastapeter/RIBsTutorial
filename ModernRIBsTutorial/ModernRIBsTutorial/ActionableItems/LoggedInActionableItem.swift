//
//  LoggedInActionableItem.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/27.
//

import Foundation
import RxSwift
import Combine

public protocol LoggedInActionableItem: AnyObject {
    func launchGame(with id: String?) -> AnyPublisher<(LoggedInActionableItem, ()), Error>
}
