//
//  AppDelegate.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit
import VolteCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let storageController = StorageController()
    private let accountController = AccountController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        BuddyBuildSDK.setup()

        storageController.load().startWithCompleted {
            print("Storage initialized!")
        }
        

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootViewController(accountController: accountController, storageController: storageController)
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

}
