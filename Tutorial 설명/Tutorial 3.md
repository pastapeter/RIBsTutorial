# iOS Tutorial 3

# RIBs Dependency Injection and Communication

<img width="587" alt="스크린샷_2022-01-19_오후_4 12 28" src="https://user-images.githubusercontent.com/69891604/150307995-e8f04df3-73a0-4fd3-85bb-a15f1719fe40.png">

튜토리얼3에서는 새로운 RIB을 만들지 않고, 현재 RIB을 수정하는 과정이 있을 것이다.

## Goals

틱택토 게임에서 다양한 것을 시작 화면에 추가할수 있는데, 첫번째는 어떤 플레이어 가 참여하는지를 알아서 그들의 이름을 보여줄 것이다. 2번째는 만약에 플레이어들이 연속으로 여러번 게임을 하면, 우리는 게임 스코어를 추적하면서 시작 화면에 보여줄 것이다.

**튜토리얼3의 메인 목표는 아래의 개념을 설명하는 것!**

- Builder의 `build` 메소드를 활용해서 child RIB에 dynamic dependency를 만들어주는 것
- Dependency Injection tree(DI Tree)를 활용해서 static dependencies를 만들어주는 것
    - 익스텐션이 베이스가 된다.
- RIB 생애주기를 활용해서 Rx 스트림 생애주기 관리(모던 RIB에서는 어떻게 진행해야하나...?)

## Dynamic dependencies

튜토리얼 1에서 게임의 로그인 폼을 만들고, player의 이름을 `LoggedOut` RIB에서 `Root` RIB으로 보냈습니다. 튜토리얼 2에서는 우리는 이 데이터를 사용하지 않았습니다. 이번 튜토리얼에서는 player 이름들을 RIB tree의 아래로 내려보낼 것입니다. `OffGame`과 `TicTacToe` RIB으로요

player 이름들을 dynamic dependencies로 `LoggedInBuilder`’s `build` 메서드를 통해서 `Root` RIB에서 `LoggedIn` RIB으로 보낼 것이다. 이렇게 하기 위해서, LoggedInBuildable 프로토콜이 기존의 리스너 종속성 외에 두 명의 player이름을 dynamic dependencies로 포함하도록 해야합니다.

```swift
protocol LoggedInBuildable: Buildable {
  func build(withListener listener: LoggedInListener,
						 player1Name: String,
						 player2Name: String) -> LoggedInRouting
}
```

그리고 빌드 함수를 업데이트 시켜줍니다. 

```swift
func build(withListener listener: LoggedInListener, player1Name: String, player2Name: String) -> LoggedInRouting {
    let component = LoggedInComponent(dependency: dependency, player1Name: player1Name, player2Name: player2Name)
```

이렇게 바꾸면 우리는 `LoggedInComponent`의 이니셜라이저를 변경해야겠죠. 이렇게 하면서 player의 이름을 의존성 주입 트리(DI tree)에 둘 수 있습니다. 우리는 그리고 그 이름들을 `LoggedInComponent`안에 상수로 둘 것입니다.

```swift
final class LoggedInComponent: Component<LoggedInDependency> {
  
  let player1Name: String
  let player2Name: String
  
  init(dependency: LoggedInDependency, player1Name: String, player2Name: String) {
    self.player1Name = player1Name
    self.player2Name = player2Name
    super.init(dependency: dependency)
  }
```

이렇게 하면 플레이어 이름을 `LoggedIn`의 부모로부터 제공받은 **dynamic dependencies**에서 `LoggedIn`의 자식들 중 어느 누구도 접근가능한 **static dependencies**로 편하게 변경 가능하다 (컴포넌트에서 상수로 만들고, )

다음, 플레이어 이름을 `LoggedInBuildable`의 build 메서드에 전달하도록 `RootRouter` 클래스를 업데이트 해야합니다.

```swift
func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String) {
    //Detach LoggedOut RIB.
    if let loggedOut = self.loggedOut {
      detachChild(loggedOut)
      viewController.dismiss(viewController: loggedOut.viewControllable)
      self.loggedOut = nil
    }
    
    let loggedIn = loggedInBuilder.build(withListener: interactor, player1Name: player1Name, player2Name: player2Name)
    attachChild(loggedIn)
  }
```

이러한 변화를 통해서 유저로부터 오고, `LoggedOut` RIB에서 다뤄지던 player 이름은 `LoggedIn` RIB과 그의 자식들에게 접근이 가능해졌다.

## Dynamic dependencies vs static dependencies

우리는 RIB을 만들때 player 이름들을 `LoggedIn` RIB에 dynamic하게 주입했다. (결국 build 함수에서, 의존성을 주입하는 것이 dynamic dependencies 인가?) 대신에 우리는 `LoggedIn` RIB이 이 의존성들을 staic하게 만들어서 RIB tree 아래로 보낼 수 있도록 만들었다. **하지만, 이러한 경우에, 우리는 이 의존성들을 옵셔널하게 만들 필요가 있다, 왜냐하면 플레이어의 이름은 `Root` RIB이 생겨날때 만들어지지 않기 때문이다.** (기존에 만들었던 우리의 디폴트 값이 없다고 생각한다.) 

만약에 우리가 옵셔널한 값을 생각하게 될때, 우리는 RIB code에 추가적인 복잡성을 알려줘야한다. `LoggedIn` RIB과 그 자식들은 `nil`에 대한 대응을 할수 있어야한다. 그리고 이렇게 하는 것은 그들의 책임 밖이다. 대신에 우리는 플레이어 이름들(`nil`에 대한 대응)을 이름들이 유저로부터 왔을때, 빠르게 해결해야한다. 그리고 이 짐을 앱의 다른 파트에서 제거해야한다. 적절한 범위의 의존성 주입으로 우리는 불변하는 가정을 세울 수 있고, 불합리하거나 불안정한 코드를 제거할 수 있습니다. 흠 nil에 대한 대응을 할 수 있다는 뜻인가..?

## RIB’s Dependencies and Components

RIBs에서는 

**의존성**은 RIB이 적절하게 인스턴스화하기 위해 부모로부터 필요로 하는 의존성을 나열하는 프로토콜이다. 

**컴포넌트**는 의존성 프로토콜의 구현체이다. 부모의 의존성들읠 RIB 빌더에게 제공해줄 뿐 아니라, 컴포넌트는 립 자체, 자식들을 만드는 의존성들을 가지고 있는 것에 대한 책임을 가지고 있다.

보통, 부모 RIB이 자식 RIB을 객체화할때, 부모 립은 자신의 컴포넌트를 자식의 Builder에게 생성자 의존성으로 주입한다. 주입된 컴포넌트들은 자체적으로 자식에게 노출할 의존성을 결정한다.

컴포넌츠가 가지고 있는 이 의존성들은 보통 어떤 상태(의존성 트리 아래로 내려가야하는 어떤 상태)를 가지고 있거나 생성하는데 비용이 크다는 이유, 성능을 항샹시키려는 이유로 RIB간에 공유됩니다.

## Passing the player names to the `OffGame` scope using the DI tree

현재 상태에서 플레이어 이름은 해결되었고, `LoggedIn` RIB에 주입될때, 별 다른 문제는 없다. 우리는 안전하게 의존성 트리를 통해서 `OffGame` RIB으로 이름을 내려보낼 수 있다. 이를 통해서 우리는 StartGame 버튼 옆에 이름을 보여줄 수 있다.

이를 위해서 우리는 플레이어 이름을 의존성으로서 `OffGameDependency` protocol에 선언할 것이다. 

```swift
protocol OffGameDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
  var player1Name: String {get}
  var player2Name: String {get}
}
```

여기 주석을 보면, RIB에 필요한 의존성들을 여기서 정의하라고 하는데, 이 RIB에서 만들어지면 안된다고 써있다. 무조건 부모로부터 내려와야하는것!

이 static 의존성들은 부모 RIB에 의한 생성 도중에 무조건 OffGame RIB으로 가야한다.

다음 스탭으로, 우리는 이 의존성들을 OffGame의 범위에서 사용할 수 있도록, OffGameComponent을 사용할 것이다. 

```swift
final class OffGameComponent: Component<OffGameDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
  
  fileprivate var player1Name: String {
    return dependency.player1Name
  }
  
  fileprivate var player2Name: String {
    return dependency.player2Name
  }
  
}
```

여기서 살펴봐야할 것은 프로퍼티들이 모든 `fileprivate` 이라는 것이다. 이 말은 이들이 모두 `OffGameBuilder.swift`에서만 접근 가능하다는 의미이고, 결국 자식 범위에 노출이 되지 않는다. 우리는 `LoggedInComponent` 안에서는 `fileprivate` 을 쓰지 않는다 왜냐하면 우리는 이 값들이 `OffGame` child scope으로 제공되길 원하기 때문이다.

이미 플레이어 이름들을 `LoggedInComponent`에 추가했기 때문에, 우리는 `OffGame`의 부모 범위(`LoggedIn` 범위)에 우리가 방금 만든 의존성들을 만족시키기 위해서 특정일을 할 필요는 없다. 

다음으로, 우리는 생성자 주입을 통해 `OffGameViewController`으로 이 의존성을 보낼 수 있다. 우리는 또한 `OffGameInteractor`로 먼저 보내고, 그리고 인터렉터가 알아서 `OffGamePresentable`의 메서드를 실행하게 해서 정보를 보여줄 수 있다. 하지만, 플레이어 이름을 보여주는 것이 어떠한 추가적인 작업이 필요하지 않기 때문에, 우리는 즉시 뷰컨트롤러로 보내서 보여주게 할 수도 있다. `OffGameViewController`에 `player1Name`과 `player2Name` 상수를 사용할 것인데, 생성자로부터 보내진 값들을 저장할 예정이다.

우선 `OffGameBuilder`를 수정해서 뷰컨트롤러에 의존성들을 주입한다.

```swift
func build(withListener listener: OffGameListener) -> OffGameRouting {
      let component = OffGameComponent(dependency: dependency)
      let viewController = OffGameViewController(player1Name: component.player1Name,
																								 player2Name: component.player2Name)
      let interactor = OffGameInteractor(presenter: viewController)
      interactor.listener = listener
      return OffGameRouter(interactor: interactor, viewController: viewController)
    }
```

그리고 `OffGameViewController`를 수정해서 플레이어 이름을 생성자에서 저장한다.

```swift
private let player1Name: String
private let player2Name: String

init(player1Name: String, player2Name: String) {
    self.player1Name = player1Name
    self.player2Name = player2Name
    super.init(nibName: nil, bundle: nil)
}
```

결국은 OffGame RIB의 뷰컨트롤러에서 UI 업데이트를 했다. 뷰컨트롤러의 코드는 Wiki에서 코드 참고를 통해 하면 될 것 같다

![simulator_screenshot_624D3F4B-7586-41A3-A386-96C21474F524](https://user-images.githubusercontent.com/69891604/150308044-8c3594ca-7f91-4e25-aa25-f42d98ae8a16.png)

## Track scores using a ReactiveX stream

지금은 앱이 game 후의 점수를 추척하고 있지 않다. 게임이 끝난 뒤에, 유저는 시작 페이지로 리다이렉트된다. 우리는 어플리케이션이 점수를 업데이트하고, 시작 페이지에 보여주고 싶다. 이를 위해서 reactive 스트림을 만들고 오브저브 해야한다.

리액티브 프로그래밍은 RIBs 아키텍처에서 자주 쓰인다. RIB 사이에서 소통을 원할하게 해주는 방법이다. 자식 RIB이 변화하는 데이터를 부모로부터 받아야할때, 데이터를 만든 쪽에서 Observable stream으로 감싼다음에 소비하는 쪽에서 그 스트림을 구독하고 있는다. 

이 튜토리얼에서 게임 점수는 `TicTacToe` RIB에서 업데이트 된다. 왜냐면 이 RIB이 현재 게임의 상태를 제어하고 있으니깐! 점수는 그리고 OffGame RIB에서 읽혀야한다, 왜냐면 `OffGame` RIB에서 가지고 있는 스크린에 보여야하니깐! `TicTacToe`와 `OffGame`은 서로를 알지 못하고, 바로 데이터를 교환할수도 없다. 하지만, 이 둘다 같은 부모(`LoggedIn` RIB)를 가지고 있다. 우리는 그렇기 떄문에 점수 스트림을 `LoggedIn` RIB에서 만들어서 두 자식들에게 보내줘야한다.

`ScoreStream`이라는 파일을 `LoggedIn` 폴더에 만들어준다. 그리고 스코어 계산하는 법을 RIBs wiki 코드를 복붙한다. 하지만 여기서 주의할점은 약간 다름.. `TicTacToeInteractor.swift` 에 있는 `PlayerType`의 case를 약간 변경해야한다.

```swift
enum PlayerType: Int {
  case player1 = 1
  case player2
}
```

`ScoreStream`을 완성했다면, 이것이 Read-Only 라는 것을 알 수 있따. 따라서 `MutableScoreStream` 도 작성 되어있는것을 알 수 있다. 

shared 라는 `ScoresStream` 인스턴스를 `LoggedInComponent`에 만든다.

```swift
var mutableScoreStream: MutableScoreStream {
    return shared {
      ScoreStreamImpl()
    }
  }
```

shared 인스턴스는 싱글톤이라는 의미인데, 이 튜토리얼에서 범위 자체는 `LoggedIn` RIB과 그 아래 자식들까지이다. 이 스트림들은 대부분 상태를 가지고 있는 객체와 마찬가지로 일반적으로 범위가 지정된 싱글톤입니다. 하지만 대부분의 다른 의존성들은 상태를 가지고 있지 않은 객체이고, 공유되지도 않습니다.

`mutableScoreStream` 프로퍼티는 `fileprivate`으로 만들어지지 않았습니다. `internal`로 만들어졌죠. `mutableScoreStream` 프로퍼티는 결국 다른 곳에서도 접근 가능합니다, 왜냐면 `LoggedIn`의 자식들에서도 접근가능해야합니다. 이 요구사항을 충족시키지 않으려면, 선언파일 내에서 캡슐화하는 게 좋습니다.

게다가, RIB안에서 직접적으로 사용되는 의존성에 한해서, 그 의존성들은 컴포넌트의 기본 구현이 되어있어야한다. 단,플레이어 이름과 같은 동적 종석성에 주입되는 저장 프로퍼티는 예외이다. 

이러한 경우, `LoggedIn` RIB이 직접적으로 `mutableScoreStream`을 `LoggedInInteractor` class에서 사용하기 때문에, 기본 구현에 `mutableScoreStream`을 두는 것은 바람직하다. 

그렇지 않다면, 우리는 의존성을 익스텐션 내에 두어야한다. `LoggedInComponent+OffGame`같이!

`mutalbeScoreStream`을 `LoggedInInteractor`로 보내서, 나중에 점수를 업데이트 할수 있도록 만들어보자, 그리고 `LoggedInBuilder`를 업데이트를 해야한다.

```swift
//MARK: - Private
  private let mutableScoreStream: MutableScoreStream

// in constructor.
  init(presenter: LoggedInPresentable, mutableScoreStream: MutableScoreStream) {
    self.mutableScoreStream = mutableScoreStream
    super.init(presenter: presenter)
    presenter.listener = self
  }
```

```swift
let interactor = LoggedInInteractor(presenter: viewcontroller, mutableScoreStream: component.mutableScoreStream)
```

## Passing a read-only `ScoreStream` down to `OffGame` scope for displaying

현재 우리는 read-only 버전인 `ScoreStream`을 `OffGame` RIB으로 내려보내고 싶다. 그렇게 해서 우리는 플레이어의 점수(하지만 업데이트는 안댐)를 보여줄수 있다. `ScoreStream`을 OffGame RIB 범위 내의 `OffGameDependency` 프로토콜을 의존성으로 선언한다.

```swift
protocol OffGameDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
  var player1Name: String {get}
  var player2Name: String {get}
  var scoreStream: ScoreStream { get }
}
```

그리고 우리는 `OffGameComponent` 내의 현재 범위에 의존성을 제공한다.

```swift
final class OffGameComponent: Component<OffGameDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
  
  fileprivate var player1Name: String {
    return dependency.player1Name
  }
  
  fileprivate var player2Name: String {
    return dependency.player2Name
  }
  
  fileprivate var scoreStream: ScoreStream {
    return dependency.scoreStream
  }
  
}
```

`OffGame`의 빌더는 `OffGameInteractor`에게 스트림을 주입하기위해서 변경해야한다.

```swift
func build(withListener listener: OffGameListener) -> OffGameRouting {
        let component = OffGameComponent(dependency: dependency)
      let viewController = OffGameViewController(player1Name: component.player1Name, player2Name: component.player2Name)
      let interactor = OffGameInteractor(presenter: viewController, scoreStream: component.scoreStream)
        interactor.listener = listener
        return OffGameRouter(interactor: interactor, viewController: viewController)
    }
```

그리고 우리는 `OffGameInteractor` 생성자가 `scoreStream` 주입을 받도록 만들고, private 상수로 저장하도록 한다.

```swift
private let scoreStream: ScoreStream

init(presenter: OffGamePresentable, scoreStream: ScoreStream) {
    self.scoreStream = scoreStream
    super.init(presenter: presenter)
    presenter.listener = self
  }
```

score 스트림 변수를 `OffGame`의 컴포넌트에 정의했을때, 우리는 `fileprivate`으로 만들어줬다, `LoggedIn` RIB과 반대로. 이 이유는 우리는 이 의존성을 `OffGame`의 자식들에게 보여줄 필요가 없기 때문이다. 

read-only score 스트림이 `OffGame` 범위 내에서만 필요하고, `LoggedIn` RIB에서는 쓰이지 않기 때문에, 우리는 scoreStream 의존성을 `LoggedInComponent+OffGame` 익스텐션에 넣는다. 

```swift
extension LoggedInComponent: OffGameDependency {
    // TODO: Implement properties to provide for OffGame scope.
  var scoreStream: ScoreStream {
    return mutableScoreStream
  }
}
```

## Display the scores by subscribing to the score stream

`OffGame` RIB은 score 스트림을 구독하고 있어야한다. 스트림에 의해서 방출된 새로운 `Score` 값이 알려진 뒤에는, `OffGamePresentable`이 이 값을 뷰컨트롤러로 하여금 보여줘야한다. 반응형 구독을 쓰면서, 우리는 이 저장된 상태를 버리고, 자동적으로 UI가 데이터에 의해 변화하도록 할 수 있다.

`OffGamePresentable` 프로토콜을 업데이트를 해서 우리는 score값을 바꿀 수 있다. 이 프로토콜은 인터렉터와 뷰와 서로 소통할수 있도록 한 것이다.

```swift
protocol OffGamePresentable: Presentable {
  // TODO: Declare methods the interactor can invoke the presenter to present data.
  var listener: OffGamePresentableListener? { get set }
  func set(score: Score)
}
```

우리는 `OffGameInteractor`에 구독을 만들고, `OffGamePresentable`이 스트림이 값을 내뿜을 때마다 새로운 점수로 변경해줘야한다.

```swift
private func updateScore() {
    scoreStream.score
      .subscribe (onNext: { (score: Score) in
        self.presenter.set(score: score)
      }).disposed(by: disposeBag)
  }
```

- 이건 튜토리얼의 예시

> 여기서 `disposeOnDeactivate` extension을 사용해서 Rxsubscrption’s lifecycle에 대응했다. 이름에서 알수 있듯, 구독은 저절로 interactor가 없어지면 사라진다.
> 
- 하지만 나는 그냥 `disposeBag` 에 넣었다 왜냐하면 `disposeOnDeactivate` 은 현재 안쓰이고, `cancelOnDeactivate` 이 쓰이지만, 이것은 `interactor` 의 내부함수이고, modern RIB이기 떄문에 이 함수를 쓰려면 컴바인을 써야했던것!

우리는 이제 `updateScore`을 `OffGameInteractor`의 `didBecomeActive` 생애주기 함수에 넣어서 실행한다. 이것은 `OffGameInteractor`가 실행될 때 새로운 구독이 생기고 사라지면 저절로 구독을 해제한다.

```swift
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
```

그리고 이제는 `OffGameViewController`가 점수가 보이도록 만들면 된다.

## Updating the score stream when a game is over

게임이 끝이나면, TicTacToe RIB은 리스너를 호출하여 LoggedInInteractor를 호출한다. LoggedInInteractor에서 점수 스트림을 업데이트해야한다.

TicTacToe의 리스너를 업데이트해서 게임 이긴사람의 정보를 공유하게 한다.

```swift
protocol TicTacToeListener: AnyObject {
  func gameDidEnd(withWinner winner: PlayerType?)
  // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}
```

그 뒤에 우리는 `TicTacToeInteractor`의 구현을 통해서 이긴 사람을 리스너로 보낼 수 있다.

 이긴 사람의 정보를 보내는 것에는 여러가지가 있다. `TicTacToeInteractor`에 지역 변수로 이긴 사람을 저장할 수도 있고, `TicTacToeViewController`가 `closeGame` 메서드를 통해서 유저가 alert를 닫았을 때, 이긴사람을 인터렉터로 보내게 하는 방법도 있다. 기술적으로 말하면, 두가지 방법 모두 옳은 방법이라고 한다. 하지만, 여기서 두가지 방법의 장단점을 확인할 수 있다.

`TicTacToeInteractor`에 지역 변수로 저장하는 방법에서, 장점은 우리는 모든 필요한 데이터를 interactor 안에서 캡슐화할 수 있다. 하지만 단점은 우리는 지역적이고, 변화할수 있는 상태를 유지해야한다는 것이다. 이것은 어쩌면 RIB의 범위가 넓기 때문에, 해결될 수 있다.  무슨말? 각각의 RIB의 지역적인 상태는 잘 캡슐화 되어 있고, 잘 제한되어있다. 우리가 `TicTacToe` RIB을 게임이 시작될때 만들때, 전의 것은 그 지역변수들과 함께 해체된다.

만약에 뷰컨트롤러로부터 데이터를 받는 접근으로 갔을 때, 우리는 인터렉터 내부에 지역적이고 변화할 수 있는 상태를 저장하는것은 막을 수 있다. 하지만, 비즈니스 로직을 짤 때, 뷰컨트롤러와의 연결을 생각하고 작성해야한다. 

두가지 접근방법에서 우리가 최선을 위해서는, 클로저를 사용한다. 인터렉터가 뷰컨트롤러에게 게임이 끝났다는 것을 알릴 때, 인터렉터는 뷰컨트롤러가 상태를 업데이트 한 뒤에 불릴 수 있는 컴플리션 핸들러를 제공할 수 있다. 이것은 승리자를 `TicTacToeInteractor`에서 캡슐화하고, 추가적인 상태를 저장안해도된다. 또한 이는 뷰컨트롤러 리스너에 있는 `closeGame` 메서드를 필요없게한다.

점수의 업데이트를 위해 컴플리션 핸들러 사용을 살펴보자!

`TicTacToePresentableListener`에서 `closeGame` 메서드를 제거한다.

```swift
protocol TicTacToePresentableListener: AnyObject {
  // TODO: Declare properties and methods that the view controller can invoke to perform
  // business logic, such as signIn(). This protocol is implemented by the corresponding
  // interactor class.
  func placeCurrentPlayerMark(atRow row: Int, col: Int)
}
```

`TicTacToeViewController`에서, `announce` 메서드를 컴플리션 핸들러를 인자로 받도록 변경하고, 유저가 alert를 없앤 뒤에 불러지도록 변경한다.

```swift
func announce(winner: PlayerType?, withCompletionHandler handler: @escaping() -> ()) {
      let winnerString: String = {
        if let winner = winner {
          switch winner {
          case .player1:
              return "Red won!"
          case .player2:
              return "Blue won!"
          }
        } else {
          return "It's a draw"
        }
      }()
      let alert = UIAlertController(title: "\(winnerString) Won!", message: nil, preferredStyle: .alert)
    let closeAction = UIAlertAction(title: "Close Game", style: UIAlertAction.Style.default) { _ in
          handler()
      }
      alert.addAction(closeAction)
      present(alert, animated: true, completion: nil)
  }
```

`TicTacToePresentable` 프로토콜에서, `announce`의 선언을 변경한다.

```swift
protocol TicTacToePresentable: Presentable {
  var listener: TicTacToePresentableListener? { get set }
  func setCell(atRow row: Int, col: Int, withPlayerType playerType: PlayerType)
  func announce(winner: PlayerType?, withCompletionHandler handler: @escaping () -> ())
  // TODO: Declare methods the interactor can invoke the presenter to present data.
}
```

TicTacToeInteractor에서 announce를 부르는 곳을 변화시켜야한다.

```swift
func placeCurrentPlayerMark(atRow row: Int, col: Int) {
    guard board[row][col] == nil else {
      return
    }
    
    let currentPlayer = getAndFlipCurrentPlayer()
    board[row][col] = currentPlayer
    presenter.setCell(atRow: row, col: col, withPlayerType: currentPlayer)
    
    if let winner = checkWinner() {
      presenter.announce(winner: winner, withCompletionHandler: {
        self.listener?.gameDidEnd(withWinner: winner)
      })
    }
  }
```

마지막으로, `LoggedInInteractor`에서 `gameDidEnd` 메서드의 구현을 변경해서 점수 스트림을 업데이트를 하게 만들어야한다.

```swift
func gameDidEnd(withWinner winner: PlayerType?) {
    if let winner = winner {
      mutableScoreStream.updateScore(withWinner: winner)
    }
    router?.routeToOffGame()
  }
```

## Bonus Exercises

- TicTacToe RIB에도 의존성 주입을 통해서 뷰컨트롤러에 저장하기

```swift
protocol TicTacToeDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
  var player1Name: String {get}
  var player2Name: String {get}
}
```

```swift
final class TicTacToeComponent: Component<TicTacToeDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
  fileprivate var player1Name: String {
    return dependency.player1Name
  }
  
  fileprivate var player2Name: String {
    return dependency.player2Name
  }
  
}
```

```swift
func build(withListener listener: TicTacToeListener) -> TicTacToeRouting {
        let component = TicTacToeComponent(dependency: dependency)
      let viewController = TicTacToeViewController(player1Name: component.player1Name, player2Name: component.player2Name)
        let interactor = TicTacToeInteractor(presenter: viewController)
        interactor.listener = listener
        return TicTacToeRouter(interactor: interactor, viewController: viewController)
    }
```

- Draw 하게 만드는 것

```swift
if !board.contains(where: { row in
        row.contains(nil) == true
      }) {
        presenter.announce(winner: nil, withCompletionHandler: {
          self.listener?.gameDidEnd(withWinner: nil)
        })
      }
```

## 튜토리얼 3을 하면서 느낀점

**static Dependency랑 dynamic Dependency의 정확한 차이점은 잘 모르겠다 (스터디 때 질문사항)**

내가 생각하기에는 build 함수에 넣었을때, dynamic인것같다. 즉, 부모 RIB에서 의존성 트리를 통해 내려받지 않고, build 함수를 이용해서 만드는 것? 그리고 그 뒤에 아래 트리에서 사용할 수 있도록 static(부모에서 의존성 인자를 넣는것?)으로 의존성을 계속 내려보내는것? 이라고 생각함

Root RIB에서 static으로 안만든 이유는 Root RIB에서 static 의존성을 만들어야했다면, 옵셔널을 생각해야했다는 것!

**의존성과 컴포넌트(이것도 잘 감이 오지는 않는다)**

컴포넌트가 의존성의 구현체라고는 하는데, 컴포넌트 파일을 한번 보면, A 컴포넌트는 A 의존성을 프로퍼티로 가지고있다. 그리고 A 컴포넌트는 Dependency를 준수한다. 컴포넌트는 의존성 프로퍼티에 접근해서 저장한 값을 가져온다. 

**무슨효과인지..?**

점수를 추적하고, 점수를 보여주기는 것은 다른 RIB에서 이루어진다. 이 둘은 공유하는 부모 RIB이 있다. 그렇기 때문에 우리는 부모 RIB에서 스트림을 만들어준다. 이 때, 자식들과 공유할 무언가는 컴포넌트에 만들기!

근데 shared로 만들면 싱글톤으로 만들겠다는 것임 → 스트림은 상태를 저장하기 때문에, 싱글톤으로 만들어준다. 

컴포넌트에 우리가 구현하는 건, 그 RIB에서 쓰이는 것만 구현한다. 혹은 dynamic dependency로 주입되는 저장 프로퍼티도 컴포넌트 내에 구현한다. 

그렇지 않은 경우(어디에 전달되는 용도의 의존성이면 전달 child을 구현하는 부분의 익스텐션에 넣어야함) → scoreStream(offgame으로 스트림을 전달할 뿐)

**<흐름>**

**LoggedIn → Offgame에게 스트림을 내려보냄 → offGame은 스트림을 구독하고 있다.**

**LoggedIn → TicTacToe에서 게임 결과를  listener 인터페이스로 올려보낸다. → LoggedIn에서 그에 맞게 위너가 누가 이겼는지를 확인하고 점수를 올린다 → 이를 구독하고 있는 offGame의 인터페이스를 변화시킨다.**
