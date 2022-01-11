//
//  LoggedInRouter.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs

protocol LoggedInInteractable: Interactable, OffGameListener, TicTacToeListener {
  var router: LoggedInRouting? { get set }
  var listener: LoggedInListener? { get set }
}

protocol LoggedInViewControllable: ViewControllable {
  // TODO: Declare methods the router invokes to manipulate the view hierarchy.
  func present(viewController: ViewControllable)
  func dismiss(viewController: ViewControllable)
}

final class LoggedInRouter: ViewableRouter<LoggedInInteractable, LoggedInViewControllable>, LoggedInRouting {
  
  override func didLoad() {
    super.didLoad()
    attachOffGame()
  }
  
  // TODO: Constructor inject child builder protocols to allow building children.
  init(interactor: LoggedInInteractable,
       viewController: LoggedInViewControllable,
       offGameBuilder: OffGameBuildable,
       tictactoeBuilder: TicTacToeBuildable) {
//    self.viewController = viewController // Uber Tutorial에는 존재
    self.offGameBuilder = offGameBuilder
    self.TicTacToeBuilder = tictactoeBuilder
    super.init(interactor: interactor, viewController: viewController)
    interactor.router = self
  }
  
  func routeToOffGame() {
    detachCurrentChild()
    attachOffGame()
  }
  
  //MARK: - private
  private let offGameBuilder: OffGameBuildable
  private var currentChild: ViewableRouting?
  private let TicTacToeBuilder: TicTacToeBuildable
  
  func routeToTicTacToe() {
    //detach OffGame
    detachCurrentChild()
    attachTicTacToe()
  }
  
  private func attachTicTacToe() {
    let tictactoe = TicTacToeBuilder.build(withListener: interactor)
    self.currentChild = tictactoe
    attachChild(tictactoe)
    viewController.present(viewController: tictactoe.viewControllable)
  }
  
  private func attachOffGame() {
    let offGame = offGameBuilder.build(withListener: interactor)
    self.currentChild = offGame
    attachChild(offGame)
    viewController.present(viewController: offGame.viewControllable)
  }
  
  func cleanupViews() {
    if let currentChild = currentChild {
      viewController.dismiss(viewController: currentChild.viewControllable)
    }
  }
  
  private func detachCurrentChild() {
    if let currentChild = currentChild {
      detachChild(currentChild)
      viewController.dismiss(viewController: currentChild.viewControllable)
    }
  }

}
