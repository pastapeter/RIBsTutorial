//
//  LoggedInComponent+TicTacToe.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs

/// The dependencies needed from the parent scope of LoggedIn to provide for the TicTacToe scope.
// TODO: Update LoggedInDependency protocol to inherit this protocol.
protocol LoggedInDependencyTicTacToe: Dependency {
    // TODO: Declare dependencies needed from the parent scope of LoggedIn to provide dependencies
    // for the TicTacToe scope.
}

extension LoggedInComponent: TicTacToeDependency {
    // TODO: Implement properties to provide for TicTacToe scope.
}
