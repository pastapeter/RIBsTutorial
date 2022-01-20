//
//  LoggedInInteractor.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs

protocol LoggedInRouting: ViewableRouting {
  func routeToTicTacToe()
  func routeToOffGame()
  func cleanupViews()
}

protocol LoggedInPresentable: Presentable {
  var listener: LoggedInPresentableListener? { get set }
  // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol LoggedInListener: AnyObject {
  // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class LoggedInInteractor: PresentableInteractor<LoggedInPresentable>, LoggedInInteractable, LoggedInPresentableListener {
  
  weak var router: LoggedInRouting?
  weak var listener: LoggedInListener?
  
  // TODO: Add additional dependencies to constructor. Do not perform any logic
  // in constructor.
  init(presenter: LoggedInPresentable, mutableScoreStream: MutableScoreStream) {
    self.mutableScoreStream = mutableScoreStream
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
  
  // 게임시작하면 routeToTicTacToe
  func didStartGame() {
    router?.routeToTicTacToe()
  }
  
  // 게임 끝나면 routeToOffGame
  func gameDidEnd(withWinner winner: PlayerType?) {
    if let winner = winner {
      mutableScoreStream.updateScore(withWinner: winner)
    }
    router?.routeToOffGame()
  }
  
  //MARK: - Private
  private let mutableScoreStream: MutableScoreStream

}
