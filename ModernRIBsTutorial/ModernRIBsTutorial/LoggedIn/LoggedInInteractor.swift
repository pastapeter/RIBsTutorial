//
//  LoggedInInteractor.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs
import Combine

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

final class LoggedInInteractor: PresentableInteractor<LoggedInPresentable>, LoggedInInteractable, LoggedInPresentableListener, LoggedInActionableItem {
  
  func launchGame(with id: String?) -> AnyPublisher<(LoggedInActionableItem, ()), Error> {
    let game: Game? = games.first { game in
            return game.id.lowercased() == id?.lowercased()
        }

        if let game = game {
            router?.routeToGame(with: game.builder)
        }

    return Published<Any>.Just((self, ()))
  }
  
  
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
