//
//  RootRouter.swift
//  ModernRIBsTutorial
//
//  Created by Ppop on 2021/12/28.
//

import ModernRIBs

protocol RootInteractable: Interactable, LoggedOutListener, LoggedInListener {
  var router: RootRouting? { get set }
  var listener: RootListener? { get set }
}

protocol RootViewControllable: ViewControllable {
  func present(viewController: ViewControllable)
  func dismiss(viewController: ViewControllable)
}

final class RootRouter: LaunchRouter<RootInteractable, RootViewControllable>, RootRouting {
  
  init(interactor: RootInteractable,
       viewController: RootViewControllable,
       loggedOutBuilder: LoggedOutBuildable,
       loggedInBuilder: LoggedInBuildable) {
    self.loggedOutBuilder = loggedOutBuilder
    self.loggedInBuilder = loggedInBuilder
    super.init(interactor: interactor,
               viewController: viewController)
    interactor.router = self
  }
  
  override func didLoad() {
    super.didLoad()
    
    let loggedOut = loggedOutBuilder.build(withListener: interactor)
    self.loggedOut = loggedOut
    attachChild(loggedOut)
    viewController.present(viewController: loggedOut.viewControllable)
  }
  
  //MARK: - RootRouting
  
  func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String) {
    //Detach LoggedOut RIB.
    if let loggedOut = self.loggedOut {
      detachChild(loggedOut)
      viewController.dismiss(viewController: loggedOut.viewControllable)
      self.loggedOut = nil
    }
    
    let loggedIn = loggedInBuilder.build(withListener: interactor, player1Name: player1Name, player2Name: player2Name)
    attachChild(loggedIn)
  }
  
  
  // MARK: - Private
  
  private let loggedOutBuilder: LoggedOutBuildable
  private let loggedInBuilder: LoggedInBuildable
  
  private var loggedOut: ViewableRouting?
}
