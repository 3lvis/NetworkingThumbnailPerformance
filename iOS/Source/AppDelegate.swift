import UIKit
import Networking

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?
    let networking = Networking(baseURL: "http://placehold.it")
}

extension AppDelegate: UIApplicationDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        guard let window = self.window else { fatalError("Window not found") }

        let numberOfColumns = CGFloat(4)
        let layout = UICollectionViewFlowLayout()
        let bounds = UIScreen.mainScreen().bounds
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        let size = (bounds.width - numberOfColumns) / numberOfColumns
        layout.itemSize = CGSize(width: size, height: size)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

        let controller = PhotosController(networking: self.networking, collectionViewLayout: layout)
        controller.title = "Remote"
        let navigationController = UINavigationController(rootViewController: controller)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        return true
    }
}
