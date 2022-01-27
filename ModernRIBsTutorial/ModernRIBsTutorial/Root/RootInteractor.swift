//
//  RootInteractor.swift
//  ModernRIBsTutorial
//
//  Created by Ppop on 2021/12/28.
//

import ModernRIBs
import Foundation
import Combine
import UIKit

protocol RootRouting: ViewableRouting {
  // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
  func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String)
}

protocol RootPresentable: Presentable {
  var listener: RootPresentableListener? { get set }
  // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol RootListener: AnyObject {
  // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class RootInteractor: PresentableInteractor<RootPresentable>, RootInteractable, RootPresentableListener, UrlHandler, RootActionableItem {
  
  private let loggedInActionableItemSubject = PassthroughSubject<LoggedInActionableItem, Error>()
  
//  private let loggedInActionableItemSubject = ReplaySubject<LoggedInActionableItem>.create(bufferSize: 1)
  
  func waitForLogin() -> AnyPublisher<(LoggedInActionableItem, ()), Error> {
    return loggedInActionableItemSubject
      .map { }
  }
  
  func handle(_ url: URL) {
    let launchGameWorkflow = LaunchGameWorkflow(url: url)
    launchGameWorkflow
      .subscribe(self)
      .disposeOnDeactivate(interactor: self)
  }
  
  
  weak var router: RootRouting?
  weak var listener: RootListener?
  
  func didLogin(withPlayer1Name player1Name: String, player2Name: String) {
    router?.routeToLoggedIn(withPlayer1Name: player1Name, player2Name: player2Name)
  }
  
  // TODO: Add additional dependencies to constructor. Do not perform any logic
  // in constructor.
  override init(presenter: RootPresentable) {
    super.init(presenter: presenter)
    presenter.listener = self
  }
  
  override func didBecomeActive() {
    super.didBecomeActive()
    // TODO: Implement business logic here.
  }
  
  override func willResignActive() {
    super.willResignActive()
    // TODO: Pause any business logic.
  }
}
