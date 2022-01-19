//
//  LoggedInBuilder.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs

protocol LoggedInDependency: Dependency {
    var loggedInViewController: LoggedInViewControllable { get }
}

final class LoggedInComponent: Component<LoggedInDependency> {
  
  let player1Name: String
  let player2Name: String
  
  init(dependency: LoggedInDependency, player1Name: String, player2Name: String) {
    self.player1Name = player1Name
    self.player2Name = player2Name 
    super.init(dependency: dependency)
  }
  
  var mutableScoreStream: MutableScoreStream {
    return shared {
      ScoreStreamImpl()
    }
  }

    fileprivate var loggedInViewController: LoggedInViewControllable {
        return dependency.loggedInViewController
    }
}

// MARK: - Builder

protocol LoggedInBuildable: Buildable {
  func build(withListener listener: LoggedInListener, player1Name: String, player2Name: String) -> LoggedInRouting
}

final class LoggedInBuilder: Builder<LoggedInDependency>, LoggedInBuildable {

    override init(dependency: LoggedInDependency) {
        super.init(dependency: dependency)
    }

  func build(withListener listener: LoggedInListener, player1Name: String, player2Name: String) -> LoggedInRouting {
    let component = LoggedInComponent(dependency: dependency, player1Name: player1Name, player2Name: player2Name)
        let viewcontroller = LoggedInViewController()
      
    let interactor = LoggedInInteractor(presenter: viewcontroller, mutableScoreStream: component.mutableScoreStream)
        interactor.listener = listener
      
        // offGameBuilder 넣어주기
        let offGameBuilder = OffGameBuilder(dependency: component)
        // tictactoeBuilder 넣어주기
        let tictactoeBuilder = TicTacToeBuilder(dependency: component)
      
        return LoggedInRouter(interactor: interactor,
                              viewController: component.loggedInViewController, offGameBuilder: offGameBuilder, tictactoeBuilder: tictactoeBuilder)
    }
}
