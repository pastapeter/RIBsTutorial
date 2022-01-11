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

    fileprivate var loggedInViewController: LoggedInViewControllable {
        return dependency.loggedInViewController
    }
}

// MARK: - Builder

protocol LoggedInBuildable: Buildable {
    func build(withListener listener: LoggedInListener) -> LoggedInRouting
}

final class LoggedInBuilder: Builder<LoggedInDependency>, LoggedInBuildable {

    override init(dependency: LoggedInDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: LoggedInListener) -> LoggedInRouting {
        let component = LoggedInComponent(dependency: dependency)
        let viewcontroller = LoggedInViewController()
      
        let interactor = LoggedInInteractor(presenter: viewcontroller) // 이게 맞나?
        interactor.listener = listener
      
        // offGameBuilder 넣어주기
        let offGameBuilder = OffGameBuilder(dependency: component)
        // tictactoeBuilder 넣어주기
        let tictactoeBuilder = TicTacToeBuilder(dependency: component)
      
        return LoggedInRouter(interactor: interactor,
                              viewController: component.loggedInViewController, offGameBuilder: offGameBuilder, tictactoeBuilder: tictactoeBuilder)
    }
}
