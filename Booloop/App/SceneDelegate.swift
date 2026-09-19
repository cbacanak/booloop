import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let nav = UINavigationController(rootViewController: LevelListViewController())
        nav.isNavigationBarHidden = true
        #if DEBUG
        // Simülatörde yerleşim kontrolü için: `-BooloopOpenLevel N` doğrudan N. seviyeyi açar.
        let openLevel = UserDefaults.standard.integer(forKey: "BooloopOpenLevel")
        if openLevel > 0 { nav.pushViewController(GameViewController(levelNumber: openLevel), animated: false) }
        #endif
        window.rootViewController = nav
        window.overrideUserInterfaceStyle = .dark
        self.window = window
        window.makeKeyAndVisible()
    }
}
