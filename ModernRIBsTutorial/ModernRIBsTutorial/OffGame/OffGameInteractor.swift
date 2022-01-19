//
//  OffGameInteractor.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs
import RxSwift

protocol OffGameRouting: ViewableRouting {
  // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol OffGamePresentable: Presentable {
  // TODO: Declare methods the interactor can invoke the presenter to present data.
  var listener: OffGamePresentableListener? { get set }
  func set(score: Score)
}

protocol OffGameListener: AnyObject {
  // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
  func didStartGame()
}

final class OffGameInteractor: PresentableInteractor<OffGamePresentable>, OffGameInteractable, OffGamePresentableListener {
  
  weak var router: OffGameRouting?
  weak var listener: OffGameListener?
  
  // TODO: Add additional dependencies to constructor. Do not perform any logic
  // in constructor.
  init(presenter: OffGamePresentable, scoreStream: ScoreStream) {
    self.scoreStream = scoreStream
    super.init(presenter: presenter)
    presenter.listener = self
  }
  
  override func didBecomeActive() {
    super.didBecomeActive()
    // TODO: Implement business logic here.
    updateScore()
  }
  
  override func willResignActive() {
    super.willResignActive()
    self.disposeBag = DisposeBag()
    // TODO: Pause any business logic.
  }
  
  func startGame() {
    listener?.didStartGame()
  }
  
  //MARK: - private
  private let scoreStream: ScoreStream
  private var disposeBag = DisposeBag()
  
  private func updateScore() {
    scoreStream.score
      .subscribe (onNext: { (score: Score) in
        self.presenter.set(score: score)
      }).disposed(by: disposeBag)
  }
}
