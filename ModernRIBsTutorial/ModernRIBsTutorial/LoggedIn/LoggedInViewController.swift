//
//  LoggedInViewController.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs
import UIKit

protocol LoggedInPresentableListener: AnyObject {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
}

final class LoggedInViewController: UIViewController, LoggedInPresentable, LoggedInViewControllable {
  
  func present(viewController: ViewControllable) {
      present(viewController.uiviewController, animated: true, completion: nil)
  }

func dismiss(viewController: ViewControllable) {
  if presentedViewController == viewController.uiviewController {
    dismiss(animated: true, completion: nil)
  }
}
  

    weak var listener: LoggedInPresentableListener?
}
