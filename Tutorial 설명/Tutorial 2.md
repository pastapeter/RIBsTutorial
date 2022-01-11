# Tutorial 2

## 튜토리얼 2의 목표

---

- 자식 RIB과 부모 RIB이 소통하는 것을 배우는 것
- 부모 인터렉터가 결정하는데로 자식 rib을 붙이고, 떼어내고 하는 것
- viewless RIB을 만드는 것
    - 뷰가 없는 Rib이 detached 되었을때 뷰의 변경사항을 초기화하는것?
- 부모 RIB이 처음 로드 되었을때 자식 RIB이 바로 붙는것(attach)
- UNIT TEST

## 튜토리얼 2에서 만들 프로젝트 구조

---

<img width="641" alt="스크린샷_2022-01-09_오후_8 50 41" src="https://user-images.githubusercontent.com/69891604/148896196-99b2b3a4-4727-42d4-bf35-7c60c65289ad.png">
슈번호

특히 여기서 LoggedIn RIB는 Viewless RIB으로 TicTacToe RIB과 OffGame RIB을 스위치 해주는 목적을 가지고 있다. 

## 부모 RIB과 소통

---

Login 버튼을 누르면 바로 Start Game View 가 보여야한다. 

LoggedOut RIB은 Root RIB에게 login Action 에 대한 정보를 주어야한다.

그 뒤에 Root 라우터는 LoggedOut RIB을 detach 하고 LoggedIn RIB으로 attach 하는 switch 동작을 수행해야한다. 

그렇게 하기 위해서는 로그인 이벤트(Logged Out RIB)를 Listener interface(protocol)를 통해서 ROOT RIB으로 전달해야한다.

```jsx
protocol LoggedOutListener: AnyObject {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
  func didLogin(withPlayer1Name player1Name: String, player2Name: String)
}
```

이 리스너 프로토콜은 어떤 RIB이던 LoggedOut RIB을 자식으로 가졌다면, 무조건 구현해야한다는 것을 보여준다. 그리고 컴파일러가 부모와 자식들 간의 계약을 강제한다는 것을 보여준다. 

새롭게 만들어진 Listener를 실행시키기 위해서 LoggedOutInteractor 안에 있는 login 함수의 구현을 변경한다. 

```jsx
func login(withPlayerName player1Name: String?, _ player2Name: String?) {
    let player1NameWithDefault = playerName(player1Name, withDefaultName: "Player 1")
    let player2NameWithDefault = playerName(player2Name, withDefaultName: "Player 2")
    listener?.didLogin(withPlayer1Name: player1NameWithDefault, player2Name: player2NameWithDefault)
    
    print("\(player1NameWithDefault) vs \(player2NameWithDefault)")
  }
```

이러한 변경사항으로, LoggedOut RIB의 리스너는 로그인 버튼을 누르는 순간을 알게 될 것이다.

<img width="742" alt="스크린샷_2022-01-09_오후_9 28 35" src="https://user-images.githubusercontent.com/69891604/148896228-75b9a5ba-6384-4c43-b62e-d80c458db559.png">


## LoggedIn RIB으로 라우팅

---

우리는 이제 Root RIB이 LoggedOut RIB에서 LoggedIn RIB로 변경해줘야한다는 것을 알고 있다.

RootRouting protocol에 LoggedIn RIB으로 갈 수 있는 메서드를 하나 만들어준다.

```jsx
protocol RootRouting: ViewableRouting {
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
  func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String)
}
```

이렇게 되면 RootInteractor와 RootRouter와 연결성이 생긴것입니다.

Root Interactor에서 RootRouting을 부르게 된다면, LoggedOutListener 프로토콜을 구현함을 통해 LoggedIn RIB으로 가는 route를 만들 수 있는 것이다. LoggedOut RIB의 부모 RIB으로, Root RIB은 그 리스너를 구현해야한다. 

```jsx
func didLogin(withPlayer1Name player1Name: String, player2Name: String) {
    router?.routeToLoggedIn(withPlayer1Name: player1Name, player2Name: player2Name)
  }
```

이 방법을 통해서 ROOT RIB은 LoggedIn RIB으로 언제든지 길을 열어 줄수 있게 되었다.

하지만 아직 LoggedIn RIB을 만들지 않았기에, Root RIB에서 Route를 해줄수 없다.

## LoggedIn RIB으로 붙여주고, LoggedOut RIB은 떼어주기

---

새로운 RIB을 만들기 위해서, LoggedInBuildable 프로토콜을 RootRouter에서 생성자 주입을 통해서 Root router가 만들어 줄 수 있게 할 수 있다. 

- RootRouter 변경사항

```jsx
init(interactor: RootInteractable,
       viewController: RootViewControllable,
       loggedOutBuilder: LoggedOutBuildable,
       loggedInBuilder: LoggedInBuildable) {
    self.loggedOutBuilder = loggedOutBuilder
    self.loggedInBuilder = loggedInBuilder
    super.init(interactor: interactor,
               viewController: viewController)
    interactor.router = self
  }
```

RootBuilder를 LoggedInBuilder가 실행되도록 변경한다. 그리고 Root Router에 주입힌다.

- RootBuilder 변경사항

```jsx
func build() -> LaunchRouting {
    let viewController = RootViewController()
    let component = RootComponent(dependency: dependency, rootViewController: viewController)
    let interactor = RootInteractor(presenter: viewController)
    
    let loggedOutBuilder = LoggedOutBuilder(dependency: component)
    let loggedInBuilder = LoggedInBuilder(dependency: component)
    return RootRouter(interactor: interactor,
                      viewController: viewController,
                      loggedOutBuilder: loggedOutBuilder,
                      loggedInBuilder: loggedInBuilder)
  }
```

Root Component를 의존성으로 지나가게 만들었지만, 일단 이건 튜토리얼 3에 나온다고 한다.

RootRouter은 LoggedInBuildable protocol에 의존한다. 이렇기 때문에 RootRouter 유닛테스트 시에 LoggedInBuildable을 테스트 mock을 지나간다. 

이렇게 해야 swizzling-based mocking이 불가능한 swift에서 처리할수 있다고 합니다. (무슨말?)

그리고 RootRouter와 LoggedInBuilder의 디커플링이 수행된다고합니다.

이렇게 해서 LoggedIn RIB을 Root RIB이 만들수 있게끔 만들었습니다.

```jsx
func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String) {
    //Detach LoggedOut RIB.
    if let loggedOut = self.loggedOut {
      detachChild(loggedOut)
      viewController.dismiss(viewController: loggedOut.viewControllable)
      self.loggedOut = nil
    }
    
    let loggedIn = loggedInBuilder.build(withListener: interactor)
    attachChild(loggedIn)
  }
```

자식RIB을 변경하기 위해서는 부모RIB은 현재 존재하는 자식RIB을 detach해야한다. 그리고 새로운 자식 RIB을 만들고 attach 해주면 해결된다. RIBs 아키텍쳐에서는 부모 라우터가 항상 자식들의 routers을 attach하고 있어야한다.

뷰 계층과 RIB 사이의 일관성을 유지하는 것도 부모 RIB의 책임이다. 만약에 자식 RIB이 ViewController 가 있다면, 부모 RIB이 present(attach시)나 dismiss(detach시) 를 해줘야 한다.

위의 코드에서는 LoggedOut RIB은 VC가 있기에, dismiss 해주고, LoggedIn RIB은 VC가 없기 때문에, present를 안해줘도 된다.

새롭게 만들어진 LoggedIn RIB의 이벤트를 받기 위해서, Root RIB은 Root interactor을 LoggedIn RIB의 리스너로 만든다. 이 방법은 Root RIB이 child RIB을 build 할때 사용된다. 하지만,  현재 시점에는 Root RIB이 LoggedIn RIB의 요청에 대응할 수 있도록 만들어져 있지 않다.

RIBs는 무조건 protocol 기반으로 된 Listener Interface를 가지고 있도록 한다. 우리는 프로토콜을 사용해서 컴파일러가 만약에 어떤 부모가 자식들의 이벤트를 구독하지 않고 있다는 것을 찾아서 애러를 발생하게 만든다. 즉, 런타임에러 대신에 컴파일 에러를 통해서 개발자들이 더 디버깅이 더 편하게 만들었다. 

코드에서 현재 우리는 LoggedInBuilder의 build 메서드에서 RootInteractable을 리스너로서 생각한다. RootInteractable은 따라서 LoggedInListener을 무조건 채택해야한다. 

결국 Root Interator 가 되려면  자식 RIB들의 Listener를 채택하라!

```jsx
protocol RootInteractable: Interactable, LoggedOutListener, LoggedInListener {
  var router: RootRouting? { get set }
  var listener: RootListener? { get set }
}
```

LoggedOut RIB을 detach하고, 뷰를 없애기 위해서는 RootViewControllable에 dismiss method도 만들어준다. 

```jsx
protocol RootViewControllable: ViewControllable {
  func present(viewController: ViewControllable)
  func dismiss(viewController: ViewControllable)
}
```

이렇게 되면서, RootRouter는 LoggedOut RIB을 완벽하게 detach할수 있게 되었고, 그리고 LoggedOut RIB의 ViewController 역시 LoggedIn RIB으로 라우팅 될때, dismiss 까지 할 수 있게 되었다.

## LoggedInViewControllable에 통과시키자?

---

LoggedIn RIB은 viewless 하다. 하지만 자식 RIB 들의 뷰들을 보여줄수 있어야한다. 그렇기 때문에, LoggedIn RIB은 조상 RIB의 view에 access 할 수 있어야한다. 여기서는 Root RIB의 view를 의미한다. (왜 그래야하는지는 아직 모르겠다.)

RootViewController는 LoggedInViewControllable을 채택한다.

```jsx
extension RootViewController: LoggedInViewControllable { }
```

LoggedInViewControllable 인스턴스를 LoggedIn RIB에 주입해야한다. 이 이유는 tutorial 3에 나온다고 한다... 일단은 LoggedInBuilder를 override 하라고 한다. 근데 여기 기존 RIBs tutorial이랑 조금 다른데,, 어떻게해야할지 모르겠다.

이렇게 되면서 LoggedIn RIB이 그 자식 RIBs 뷰들을 보여주거나 숨길수 있다. Root RIB이 LoggedinViewControllable에 있는 메서드를 사용하면서 가능하게된다.

## LoggedIn RIB이 attach 되었을 때 OffGame RIB과 바로 연결하기

---

Logged RIB이 Offgame RIB을 build하고, attach까지 할수 있게끔 만들어야 한다. LoggedIn Router의 생성자를 변경해서 OffGameBuilable 인스턴스를 주입한다. 

```jsx
init(interactor: LoggedInInteractable,
       viewController: LoggedInViewControllable,
       offGameBuilder: OffGameBuildable) {
//    self.viewController = viewController // Uber Tutorial에는 존재
    self.offGameBuilder = offGameBuilder
    super.init(interactor: interactor, viewController: viewController)
    interactor.router = self
  }

private let offGameBuilder: OffGameBuildable
```

LoggedInBuilder가 OffGameBuilder를 실행할수 있도록, 그리고 LoggedIn Router로 주입할 수 있도록 update를 해야한다.

- Build 함수의 변경사항

```jsx
final class LoggedInBuilder: Builder<LoggedInDependency>, LoggedInBuildable {

    override init(dependency: LoggedInDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: LoggedInListener) -> LoggedInRouting {
        let component = LoggedInComponent(dependency: dependency)
        let viewcontroller = LoggedInViewController()
        let interactor = LoggedInInteractor(presenter: viewcontroller) // 이게 맞나?
        interactor.listener = listener
        let offGameBuilder = OffGameBuilder(dependency: component)
        return LoggedInRouter(interactor: interactor,
                              viewController: component.loggedInViewController, offGameBuilder: offGameBuilder)
    }
}
```

말 그대로 LoggedIn Builder에서 OffgameBuilder 까지 생성중이고, 그 뒤에 LoggedInRouter에 주입까지!

또한 OffGameBuilder와 의존성 계약을 위해서는 LoggedInComponent 클래스에 OffDependency를 채택한다.  자세한 사항은 Tutorial 3 에 나온다고 한다. RIB의 의존성 익스텐션 탬플릿을 사용하면 편하다

```jsx
//
//  LoggedInComponent+OffGame.swift
//  ModernRIBsTutorial
//
//  Created by abc on 2022/01/10.
//

import ModernRIBs

/// The dependencies needed from the parent scope of LoggedIn to provide for the OffGame scope.
// TODO: Update LoggedInDependency protocol to inherit this protocol.
protocol LoggedInDependencyOffGame: Dependency {
    // TODO: Declare dependencies needed from the parent scope of LoggedIn to provide dependencies
    // for the OffGame scope.
}

extension LoggedInComponent: OffGameDependency {

    // TODO: Implement properties to provide for OffGame scope.
}
```

현재 우리는 유저가 login 하면 OffGame으로 바로 시작하고 싶다. LoggedIn RIB이 로드 되자마자 OffGame RIB으로 바로 attach 가  필요하다는 뜻. LoggedIn Router를 변경한다.

```jsx
override func didLoad() {
    super.didLoad()
    attachOffGame()
  }
```

didload를 override 해서 사용한다.

```jsx
private var currentChild: ViewableRouting?
  
  private func attachOffGame() {
    let offGame = offGameBuilder.build(withListener: interactor)
    self.currentChild = offGame
    attachChild(offGame)
    viewController.present(viewController: offGame.viewControllable)
  }
```

여기서 OffGame RIB과 소통을 하려면 부모 RIB인 LoggedIn RIB이 OffGame RIB의 리스너 인터페이스를 통해서 OffGame의 이벤트를 제공받아야한다. 각 RIB들의 의사소통은 Interactor를 통해 진행되기 때문에, Interator에 주입을 시켜주면되는데, 즉 LoggedInInteractable에 OffGameListener을 채택시켜준다. 

```jsx
protocol LoggedInInteractable: Interactable, OffGameListener {
  var router: LoggedInRouting? { get set }
  var listener: LoggedInListener? { get set }
}
```

LoggedIn RIB은 이제 OFFGame RIB과 로딩 즉시 attach 될 것이다. 그리고 OffGame RIB에서 생기는 events를 바로 알수 있다.

## LoggedIn RIB이 detach되면 attach된 view들을 치워주어야함!

---

LoggedIn RIB은 view를 가지고 있지 않고, 부모의 View 계층을 변경해주는 역할을 한다. Root RIB은 LoggedIn RIB이 변경한 view 수정들에 대해서 어찌할 방법이 없어서, 이 역할 역시 LoggedIn RIB이 해야한다.

LoggedInViewControllable에 present, dismiss를 추가해한다.

```jsx
protocol LoggedInViewControllable: ViewControllable {
  // TODO: Declare methods the router invokes to manipulate the view hierarchy.
  func present(viewController: ViewControllable)
  func dismiss(viewController: ViewControllable)
}
```

이렇게 하는 것은 LoggedIn RIB이 view가 없더라도, dismiss 하는 것이 필요하다는 것이다. 

우리는 LoggedInRouter에 cleanupViews하는 코드를 작성할 것이다. 이 함수를 통해서 현재 자식RIB의 viewcontroller를 dismiss할 예정이다.

```jsx
func cleanupViews() {
    if let currentChild = currentChild {
      viewController.dismiss(viewController: currentChild.viewControllable)
    }
  }
```

cleanupViews 는 LoggedInRouter에 있는게 맞다. Routing이 되는순간 detach해줘야하니깐! 이를 통해서 LoggedIn RIB이 부모 RIB의 뷰 계층에 detach하고 나서 뷰들을 남기지 않는다는 것을 알게 되었다.

## ‘Start Game’ 버튼을 누르면 TicTacToe RIB으로 변경하기

---

LoggedIn RIB이 OffGame RIB이랑 TicTacToe RIB과 변경을 해야한다. 다음 구현은 TicTacToe RIB과 OffGame RIB에서 변경되는 것이다.

이 방식은 LoggedIn RIB과 LoggedOut RIB이 변경되는 방식과 매우 비슷하다. Route를 하기 위해서는 LoggedInRouter에 routeTicTacToe를 구현해야한다. 그리고 OffGameViewController의 button tap과 OffGameInteractor을 연결하고, 마지막으로는 LoggedInInteractor까지 연결되게 만들어야 한다.

코드를 구현할 시에, OffGameListener의 있는 메소드를 startTicTacToe로 변경해야한다. (Unit Test에 있는 것) 그렇지 않으면 Unit Test에서 컴파일 애러가 날 것이다. 

 

## TicTacToe RIB에서 승자가 생기면, OFFGame으로 다시 가기

---

다시 OffGame으로 가기 위해서는 LoggedInRouting 프로토콜에 `RouteToOffGame()` 을 추가해줘야한다.

```jsx
protocol LoggedInRouting: ViewableRouting {
  func routeToTicTacToe()
  func routeToOffGame()
  func cleanupViews()
}
```

그리고 LoggedInRouting을 채택하고 있는 LoggedInRouter로 가서 routeToOffGame()을 구현한다.

```jsx
func routeToOffGame() {
    detachCurrentChild()
    attachOffGame()
  }
```

그리고 모든 로직이 있는 interacter로 가서 `gameDidEnd()` 함수를 만들어준다. 

```jsx
func gameDidEnd() {
    router?.routeToOffGame()
  }
```

## 튜토리얼 2를 하면서 느낀점 & 내가 이해한 바

---

- RIB 안에서 비즈니스 로직들은 다 interactor에 들어간다.
- 하지만 RIB안에 View가 있고 이 View에서 event가 발생했을 경우 아니면 혹은 interactor에서 completion이 일어났을 경우 다른 RIB 에게 알려줘야할 때가 있다
- RIBs 들은 interactor끼리 소통을 하고 소통을 한 뒤에 특정 다른 rib으로 변경해야할 시에,
    
    자식1 RIB interactor → 부모 RIB interactor → 부모 RIB 라우터 → 자식 1 RIB detach, 자식 2 RIB attach (여기서 view가 있다면 present, dismiss)를 구현해줄수 있을 것
    
- 이때 커뮤니케이션은 listener 인터페이스를 사용한다. 예를 들면, LoggedIn RIB에서 LoggedInInteractable이라는 프로토콜은 아직 Listener 프로토콜을 채택? 상속? 하는데, 근데 그 리스너들은 각자 자식 RIB의 인터렉터에 주입되어있는것이다. 의존성 주입에 대한 개념이 정확하게는 없지만 내 지식 상 약간 겹겹이 붙어있는 delegate 패턴과 유사하다는 생각이 들었다.
    - 델리게이트 패턴도 protocol 하나 만들고 하나는 주입하고 하나는 채택해서 함수 구현해서 두개의 vc를 연결하는 것인데, 이것도 비슷하다는 느낌이었다. 그래서 RIB 2개가 서로 연결이 되어있다는 느낌이었다.
- 할튼 그래서 부모 RIB의 인터렉터는 무조건 자식의 리스너를 가진다. 그렇게 되면? 자식 RIB에서 interactor을 짜게 될때, 우리가 부모 RIB 인터렉터에게 알려줄 것은 Listener protocol 에 메소드를 정의하면 될 것 같다.
- View가 있다면, RIB 탬플릿을 열어보면,  00PresentableListener 프로토콜이 있다. 여기에 interactor의 비즈니스 로직을 쓰라고 한다. 그리고 이 프로토콜을 View에 주입하는데, 그러면 뷰에서 이벤트가 발생했을때, interactor로 연결된다. 왜냐면 인터렉터는 이 프로토콜을 채택하고, 구현해놨기 때문이다.
- 그러면 이제 인터렉터로 와서 인터렉터를 구현한다. 하다가 다른 RIB으로 커뮤니케이션을 해야할 일이 있다면, 00Listener 프로토콜에 메서드를 작성한다. 00리스너는 부모 RIB의 interactable을 채택하기에 부모 RIB의 interactor와 연결할 수 있다. 결국 그렇게 되면 부모RIB의 route까지 manage할 수 있다는 것이다.
- 그러면 지금 부모 인터렉터 파일에 들어왔을때, 우리는 자식 리스너에 정의해놓은 메서드를 구현해야한다. 튜토리얼 2에서 TicTacToe 리스너 프로코톨에는 gameDidEnd()를 정의했고, 이를 받은 부모 인터렉터는 이 함수를 구현할 때, 다른 detach, attach가 일어나기 때문에, 자신의 라우터를 불러서 해결한다.
- 그러한 일이 필요할때 00Routing 이라는 프로토콜에 메서드를 정의하면된다. 인터렉터는 00Routing을 인스턴스로 가지고 있고, 라우터 클래스가 이를 채택해서 구현하고 있을 것이다.
- 그러면 우리는 라우터에 그 함수를 구현하면된다. 그렇게 되면 인터렉터가 실행 → 라우터 → attach/detach
