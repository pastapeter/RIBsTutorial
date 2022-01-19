//
//  PlayerType.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/19.
//

import UIKit

enum PlayerType: Int {
  case player1 = 1
  case player2
}

extension PlayerType {

    var color: UIColor {
        switch self {
        case .player1:
            return UIColor.red
        case .player2:
            return UIColor.blue
        }
    }
}
