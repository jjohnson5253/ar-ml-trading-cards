//
//  AppDelegate.swift
//  mtg_ar
//
//  Created by Jake on 4/19/21.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ARSceneViewController())
        window?.makeKeyAndVisible()
        return true
    }

}

