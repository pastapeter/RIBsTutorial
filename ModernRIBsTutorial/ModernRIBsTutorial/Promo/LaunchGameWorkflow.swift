//
//  LaunchGameWorkflow.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/27.
//

import Foundation
import ModernRIBs
import Combine
import RxSwift

public class LaunchGameWorkflow: Workflow<RootActionableItem> {
    public init(url: URL) {
        super.init()

        let gameId = parseGameId(from: url)

        self
        .onStep { (rootItem: RootActionableItem) -> AnyPublisher<(LoggedInActionableItem, ()), Error> in
                rootItem.waitForLogin()
            }
        .onStep { (loggedInItem: LoggedInActionableItem, _) -> AnyPublisher<(LoggedInActionableItem, ()), Error> in
                loggedInItem.launchGame(with: gameId)
            }
            .commit()
    }

    private func parseGameId(from url: URL) -> String? {
        let components = URLComponents(string: url.absoluteString)
        let items = components?.queryItems ?? []
        for item in items {
            if item.name == "gameId" {
                return item.value
            }
        }

        return nil
    }
}
