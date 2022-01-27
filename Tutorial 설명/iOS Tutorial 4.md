# iOS Tutorial 4

## Goals

튜토리얼 1 ~ 3에서는 tic-tac-toe 게임을 5개의 RIB을 사용해서 만들었다. 이번 튜토리얼에서는 deeplinking support를 앱에 추가하는 방법과, 사파리에서 URL을 열어서 새로운 게임을 시행시키는 방법에 대해서 알아보겠다.

이번 튜토리얼을 마친다면, RIB의 흐름과 액션 가능한 아이템의 기초 그리고, 딥링크를 통해서 워크플로우를 어떻게 시작하는지에 대해서 알 수 있다. `ribs-training://launchGame?gameId=ticTacToe` URL을 열어볼것이다.이 링크를 열게되면, 앱이 실행될 뿐만 아니라, 새로운 게임이 바로 실행되게 한다.

## Implementing a URL handler

딥링크는 사용자 지정 URL을 통해 앱 간 통신을 허용하는 iOS 매커니즘이다. 특정 URL 스키마의 핸들러로 자신을 등록하는 앱은 사용자가 다른 앱에서 일치하는 스키마로 URL을 열면 시작된다. 열린 앱은 수신된 URL의 내요엥 액세스할 수 있으므로, URL에 쓰여있는 상태로 전환할 수 있다.

틱택토 앱을 커스텸 URL 스키마 `ribs-training://`로 등록하기위해서, 우리는 `Info.plist`에 추가해야한다.

```swift
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.uber.TicTacToe</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ribs-training</string>
        </array>
    </dict>
</array>
```

앱으로 전송된 커스텀 URL을 다루기위해, 앱 델리케이트의 특정 부분을 변경해야한다.

`UrlHandler`라는 프로토콜 `AppDelegate.swift`을 하나 만든다. 이 프로토콜은 나중에 앱의 구체적인 URL 핸들링 로직을 담구 있는 클래스로 구현될 것이다. 

```swift
protocol UrlHandler: class {
    func handle(_ url: URL)
}
```

앱 델리케이트에 URL handler의 참조를 저장하자. 이렇게 하면 우리는 이 핸들러에게 딥링크 URL을 물어보고 받을 수 있따. 

```swift
private var urlHandler: UrlHandler?
```

앱에 딥링크가 전송될때 트리거되는 AppDelegate의 메서드를 구현하자. 이방법에서는 URL을 URL 처리기로 전달한다.

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    urlHandler?.handle(url)
    return true
  }
```

커스텀 URL은 Root RIB이 RIB 계층 구조의 맨위에 있기 때문에 처리해야한다. 루트에서 URL을 처리하면 딥링크를 수신한 후 원하는 방식으로 앱을 구성할 수 있다. Root RIB은 모든 자식들을 빌드하고 화면에 표시할 수 있기 때문이다. RootInteracotr를 URL 핸들러로 만들것이다. root Interactor가 UrlHandler와 RootActionableItem 프로토콜을 채택하게한다. RootActionableItem은 일단은 빈프로토콜이다.

```swift
final class RootInteractor: PresentableInteractor<RootPresentable>, RootInteractable, RootPresentableListener, UrlHandler
```

앱 내에서 URL을 다루기위해서, 워크플로우라는 이름을 가진 RIBs 메커니즘 사용할 것이다. 

```swift
func handle(_ url: URL) {
    let launchGameWorkflow = LaunchGameWorkflow(url: url)
    launchGameWorkflow
      .subscribe(self)
      .disposed(by: disposeBag)
  }
```

Promo 그룹에 이미 워크플로우 스텁이 있으므로 나중에 적절한 구현으로 교체해야한다.

그리고 RootBuilder를 변경해서, UrlHandler와 RootRouting 객체를 리턴하도록 한다.

```swift
protocol RootBuildable: Buildable {
  func build() -> (launchRouter: LaunchRouting, urlHandler: UrlHandler)
}
```

```swift
func build() -> (launchRouter: LaunchRouting, urlHandler: UrlHandler) {
    let viewController = RootViewController()
    let component = RootComponent(dependency: dependency, rootViewController: viewController)
    let interactor = RootInteractor(presenter: viewController)
    
    let loggedOutBuilder = LoggedOutBuilder(dependency: component)
    let loggedInBuilder = LoggedInBuilder(dependency: component)
    let router = RootRouter(interactor: interactor,
                      viewController: viewController,
                      loggedOutBuilder: loggedOutBuilder,
                      loggedInBuilder: loggedInBuilder)
    return (router, interactor)
  }
```

이러한 변화로, 우리는 urlHandler을 초기화할 수 있다.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    self.window = window
    
    let result = RootBuilder(dependency: AppComponent()).build()
    self.launchRouter = result.launchRouter
    self.urlHandler = result.urlHandler
    launchRouter?.launch(from: window)
    return true
  }
```

ribs-training:// 스키마를 가진 딥링크를 받고 나면, 앱은 RootInteractor에 정의된 workflow를 시작할 것입니다.

## Workflows and actionable Items

RIB의 용어 내에서, 워크플로우는 특정 행위를 구성하는 순서이다. 워크플로우는 RIB 트리에서 실행될 수 있다. 워크플로우의 진행에 따라서 작업은 트리를 위 아래로 이동하면서 진행될 수 있다. 일반적으로 워크플로우는 트리의 루트에서 시작하여 앱을 예상 상태로 전환할 수 있는 지점에 도달할 때까지 특정 경로를 통해 아래로 탐색한다. 기본적인 워크플로우는 액션 가능한 아이탬을 파라미터로 갖는 제너릭 클래스에 의해서 수행된다. 앱의 특정 워크플로우는 기본적인 것에서 확장된 상태이다.

워크플로우는 리액티브 스트림과 함께 돌아온다. 그리고 옵저버블에서 찾을 수 있는 것과 비슷한 API를 노출한다. 워크플로우를 시작하기 위해서, 우리는 그것을 구독해야하고, 반환된 디스포저블을 디스포즈백에 넣어줘야한다. 런치가 된 이후, 워크 플로우는 비동기적으로 하나씩 단계를 수행해나갈 것이다. 

워크플로우의 단계는 액션 가능한 아이탬과 관련된 값의 쌍으로 정의할 수 있다. 액션 가능한 항목에는 단께 중에 실행해야하는 로직이 있다. 값에는 워크플로우가 진행됨에 따라서 결정을 내리는데 도움이 되도록, 여러 단계 간의 상태를 전달하는데 사용되는 인자 역할을 한다. 

RIB’s의 인터렉터는 워크플로우 단계를 위한 액션가능한 아이템으로 사용하고 RIB 트리를 탐색하고, 워크플로우 단계를 수행하는데 필요한 로직을 캡슐화하는것의 대한 책임이 있다. `RootInteractor`는 `RootActionableItem` 프로토콜을 채택하고 있다. 이것은 우리는 `RootInteractor`가 `Root` RIB에서의 액션가능한 아이템의 역할을 하고 있다고 봐도된다.

## Implementing the workflow

딥링크를 받으면, 앱이 게임을 주어진 identifier을 가지고 새로운 게임을 시작해야한다. 하지만, 플레이어들이 로그인하지 않았다면, 앱은 처음에 그들이 로그인할때까지 기다리고, 이후에, 플레이어들을 게임필드로 리다이렉트 시켜야한다.

이 상황은 2개의 스텝을 가진 워크플로우로 모델링될 수 있다. 첫번째 스텝에서는, 플레이어들이 로그인되어있는지 확인하고, 필요할 경우, 플레이어들이 로그인할때까지 기다린다. 이 스텝은 Root RIB 레벨에서 진행된다. 플레이어들이 준비완료되었다고 생각이 들면, 첫번째 단계가 두번째 단계로 옵져버블 스트림을 통해서 값을 방출하면서 제어를 넘긴다. 

두번쨰 스탭은 `LoggedIn` RIB에서 수행된다. `LoggedIn` RIB은 `Root` RIB의 바로 아래 자식이다. 그래서 어떻게 게임이 시작되는지 안다. `LoggedIn` RIB의 라우터인터페이스는 게임필드로 이동하라는 트리거를 가진 `routeToGame` 메서드를 선언한다. 두번째 스탭은 이 메서드를 실행시켜야한다. 

플레이어들이 로그인할때까지 기다리는 것을 허용하는 인터페이스를 선언하자. `RootActionableItem` 프로토콜을 만들고 메소드를 만든다.

```swift
import Combine

public protocol RootActionableItem: AnyObject {
  func waitForLogin() -> Observable<(LoggedInActionableItem, ())>
}
```

여기서 보면, 이 메소드는 (다음 액션가능한 아이탬타입, 다음 값 타입) (`NextActionableItemType`, `NextValueType`) 튜플을 방출합니다. 이 튜플은 워크플로우가 다음 스텝을 만들고, 현재 스텝이 끝나면 실행하도록 합니다. observable이 처음 값을 방출할때까지, 워크플로우는 멈춰있습니다. 이러한 리액티브 패턴은 워크플로우가 비동기적으로 실행되게 만듭니다. 그리고 워크플로우는 그 안의 모든 스탭을 즉시 실행 안해도 된다는 뜻입니다. 

`NextActionableItemType`이 여기에서는 `LoggedInActionableItem`입니다. 이 말은 다음 스텝은 `LoggedIn` RIB 내부에 액션 가능한 아이템으로 만들어줘야할 이름이다. `NextValueType`은 보이드인데, `Root` RIB에서 워크플로우 체인을 따라서 내려보낼때, 내려줘야할 추가 상태가 없기 때문이다. 

이제는 `LoggedInActionableItem` 프로코톨을 만들어야한다. 

```swift
import Combine

public protocol LoggedInActionableItem: AnyObject {
    func launchGame(with id: String?) -> Observable<(LoggedInActionableItem, ())>
}
```

이 프로토콜은 워크플로우의 2번째와 마지막 스탭이다. 완료시 다른 단계를 트리거할 필요가 없으므로, `LoggedInActionableItem` 자체를 NextActionableItemType으로 반환한다. 이러한 작업은 워크플로우의 유형 제약조건을 준수하는데 필요하다. 이전단계와 같이 체인 아래로 추가 데이터를 전달할 필요가 없으므로 value는 void 이다.

워크플로우를 통해 실행될 단계들을 선언한 뒤에, 우리는 워크플로우 자체를 만들 수 있다. 이 워크플로우에 대한 딥링크가 프로포션 캠페인을 지원하기 위해 만들어졌고, 다른 프로모션 관련 코드와 가까운 워크플로우 구현을 원한다고 가정해본다면!! `Promo` 그룹으로 가서(없으면 만들기..?), `LaunchGameWorkflow.swift` 를 만들고 아래 코드를 복붙하기

```swift
public class LaunchGameWorkflow: Workflow<RootActionableItem> {
    public init(url: URL) {
        super.init()

        let gameId = parseGameId(from: url)

        self
        .onStep { (rootItem: RootActionableItem) -> Observable<(LoggedInActionableItem, ())> in
                rootItem.waitForLogin()
            }
        .onStep { (loggedInItem: LoggedInActionableItem, _) -> Observable<(LoggedInActionableItem, ())> in
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
```

코드 스니핏에서 우리는 워크플로우를 이니셜라이저 내부에서 바로 설정해줬다. 두개의 워크플로우 스텝은 각각 클로저로 만들어져있다. 이 클로저는 액션 가능한 아이템과 값을 파라미터로 받는 애들이다. 그리고 이 클로저는 (NextActionableItemType, NextValueType)의 형태로 옵저버블(publisher)를 리턴한다. 

내부를 보면, 워크플로우는 클로저를 실행하고, 클로저의 방출된 옵저버블을 구독한다. 각각의 스탭에서, 워크플로우는 옵저버블이 첫벚째 값을 방출하고, 그리고 다음 스탭으로 변경하는 것을 기다린다. 

## Integrating the `waitForLogin` step at the `Root` scope

`RootInteractor`는 이미 `RootActionableItem` 프로토콜을 채택하고 있다. 이제는 우리는 필요한 구현을 통해서 `RootInteractor` 컴파일되게만 만들면 된다.

처음으로, `RootInteractor`에 있는 `waitForLogin`을 구현해야한다. RIB을 위해서 인터렉터가 액션 가능한 아이템의 역할을 수행해야한다.

로그인을 기다리는 것은 비동기적 진행이다. 이것을 수행하기 위해서는 리액티브 서브젝트가 필요하다. `RelaySubject` 상수를 선언한다. 이것은 `LoggedInActionableItem`을 `RootInteractor`안에서 가질 수 있게 도와준다.

```swift
private let loggeedInActionalbeItemSubject = ReplaySubject<LoggedInActionableItem>.create(bufferSize: 1)
```

그다음, `waitForLogin` 메서드에서 이 서브젝트를 `Observable`로 반환해야한다. `Observable`로부터 반환된 `LoggedInActionableItem`을 가지고 있기 때문에, 사용자가 로그인 하는 것을 기다리는 워크플로우 단계는 성공했다. 그러므로 우리는 `LoggedInActionableItem`을 다음 액션가능한 아이템으로 가지고 다음 스탭으로 넘어갈 수있다,

```swift
// MARK: - RootActionableItem

func waitForLogin() -> Observable<(LoggedInActionableItem, ())> {
    return loggedInActionableItemSubject
        .map { (loggedInItem: LoggedInActionableItem) -> (LoggedInActionableItem, ()) in
            (loggedInItem, ())
        }
}
```

그리고 우리가 `Root` RIB에서 `LoggedIn` RIB으로 갔을때, 우리는 `LoggedInActionableItem`을 `RelaySubject`로 방출한다. 우리는 이것을 `RootInteractor` 내부의 `didLogin` 메서드에서 실행한다.

```swift
// MARK: - LoggedOutListener

func didLogin(withPlayer1Name player1Name: String, player2Name: String) {
    let loggedInActionableItem = router?.routeToLoggedIn(withPlayer1Name: player1Name, player2Name: player2Name)
    if let loggedInActionableItem = loggedInActionableItem {
        loggedInActionableItemSubject.onNext(loggedInActionableItem)
    }
}
```

didLogin 메서드에서 새로운 구현이 정의되면서, 우리는 RootRouting 프로토콜의 routeToLoggedIn 메서드가 LoggedInActionableItem 객체를 리턴하도록 업데이트 해야한다. 아마 저 객체는 LoggedInInteractor일 것이다. 

```swift
protocol RootRouting: ViewableRouting {
    func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String) -> LoggedInActionableItem
}
```

그리고 RootRouter를 업데이트 해야한다. 왜냐면 RootRouting 프로토콜이 변경되어있기 때문이다. 우리는 LoggedInActionableItem을 방출하도록 해야한다. (LoggedInInteractor 가 방출될 것이다.)

```swift
func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String) -> LoggedInActionableItem {
    // Detach logged out.
    if let loggedOut = self.loggedOut {
        detachChild(loggedOut)
        viewController.replaceModal(viewController: nil)
        self.loggedOut = nil
    }

    let loggedIn = loggedInBuilder.build(withListener: interactor, player1Name: player1Name, player2Name: player2Name)
    attachChild(loggedIn.router)
    return loggedIn.actionableItem
}
```

우리는 따라서 LoggedInBuildable 프로토콜을 변경한다. LoggedInRouting 과 LoggedInActionableItem이 같이 튜플형태로 리턴되도록한다.

```swift
protocol LoggedInBuildable: Buildable {
    func build(withListener listener: LoggedInListener, player1Name: String, player2Name: String) -> (router: LoggedInRouting, actionableItem: LoggedInActionableItem)
}
```

LoggedInBuilable 프로토콜이 변경되었기에, LoggedInBuilder의 빌드함수를 그에 맞도록 변경한다. 인터렉터는 이 범위에서 액션가능한 아이템이다. 

```swift
func build(withListener listener: LoggedInListener, player1Name: String, player2Name: String) -> (router: LoggedInRouting, actionableItem: LoggedInActionableItem) {
    let component = LoggedInComponent(dependency: dependency,
                                      player1Name: player1Name,
                                      player2Name: player2Name)
    let interactor = LoggedInInteractor(games: component.games)
    interactor.listener = listener

    let offGameBuilder = OffGameBuilder(dependency: component)
    let router = LoggedInRouter(interactor: interactor,
                          viewController: component.loggedInViewController,
                          offGameBuilder: offGameBuilder)
    return (router, interactor)
}
```

이러한 변화로 첫번째 워크플로우를 완성했다. 워크플로우는 사용자가 로그인할때까지 기다릴 것이고, `LoggedIn` RIB에 구현되어있는 2번째 스탭(게임시작)으로 이동할 것이다. 

## Integrating the launchGame step in the LoggedIn Scope

`LoggedInInteractor`가 `LoggedInActionableItem` protocol을 채택하도록한다. 각자 범위의 인터렉터가 범위의 액션 가능한 아이템 프로토콜을 채택해야한다.

```swift
final class LoggedInInteractor: Interactor, LoggedInInteractable, LoggedInActionableItem
```

`LoggedInActionableItem` 프로토콜이 강제하는 `launchGame` 함수를 구현한다. 이 함수는 워크플로우의 2번째 스텝에 해당한다. 

```swift
// MARK: - LoggedInActionableItem

func launchGame(with id: String?) -> Observable<(LoggedInActionableItem, ())> {
    let game: Game? = games.first { game in
        return game.id.lowercased() == id?.lowercased() 
    }

    if let game = game {
        router?.routeToGame(with: game.builder)
    }

    return Observable.just((self, ()))
}
```

이 메서드에서 보면, LoogedIn의 라우터로 하여금, 게임필드로 이동하라고 한다. 그리고 리턴 타입을 지키기 위해서 옵저버블을 다시 리턴한다. 이러한 스탭이 워크플로우의 마지막이다. 

## Tutorial 4 후의 느낀점

1. 튜토리얼 4에서는 워크플로우가 있다는 것을 알려준다. 결국은 이제 앱을 실행했을때, 어떻게 흘려보낼지! 를 알려주는 친구이다.
2. 이 워크플로우만 잘 짠다면, 앱을 굉장히 편하게 짤 수 있을 것같다는 느낌이다.
3. 특히 워크플로우에서, actionableItem을 설정해주면서, 인터렉터가 결국은 각 범위에서의 actionableItem이 된다. 그러면서 인터렉터 서로 소통하면서 인터렉터가 라우터보고 어디로 가라고 말할 수 있으니 대박이긴하다.
4. 하나의 워크플로우 스텝에서 actionItem이 끝나면 다음 actionItem으로 차례가 넘어간다.