//
//  RootComponent+LoggedIn.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs

// TODO: Update RootDependency protocol to inherit this protocol.
protocol RootDependencyLoggedIn: Dependency {
    // TODO: Declare dependencies needed from the parent scope of Root to provide dependencies
}

extension RootComponent: LoggedInDependency {
  var loggedInViewController: LoggedInViewControllable {
    return rootViewController
  }
}
