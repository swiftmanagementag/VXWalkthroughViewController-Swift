//
//  AppDelegate.swift
//  VXWalkthrough
//
//  Created by Graham Lancashire on 09.12.19.
//

import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate {
    @IBOutlet var window: UIWindow?
    @IBOutlet var navigationController: UINavigationController!

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
}
