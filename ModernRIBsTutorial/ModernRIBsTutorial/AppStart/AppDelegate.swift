//
//  AppDelegate.swift
//  ModernRIBsTutorial
//
//  Created by Ppop on 2021/12/28.
//

import UIKit

import ModernRIBs

protocol UrlHandler: AnyObject {
  func handle(_ url: URL)
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  private var launchRouter: LaunchRouting?
  private var urlHandler: UrlHandler?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    self.window = window
    
    let result = RootBuilder(dependency: AppComponent()).build()
    self.launchRouter = result.launchRouter
    self.urlHandler = result.urlHandler
    launchRouter?.launch(from: window)
    return true
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    urlHandler?.handle(url)
    return true
  }
}

