//
//  AppDelegate.swift
//  tutorial
//
//  Created by Geza Simon on 2022. 04. 12..
//

import UIKit
import FRAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    //DONE SUSPENDED
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }



    //DONE CENTR 1: add URL scheme to project properties
    //DONE CENTR 2: add handler function for custom URL scheme starting the app
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {





        FRLog.i("incoming url: \(String(describing: url))")

        if let _ = url.valueOf("code") {
            // Parse and validate URL, extract authorization code, and continue the flow:
            Browser.validateBrowserLogin(url: url)
            return true


        } //TODO SUSPENDED

        else {
            return false
        }
    }


    
}

