//
//  AppDelegate.swift
//  GameSeerr
//
//  Created by Dean Goodwin on ...
//
//  Sets up Firebase and global UI appearance
//

import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // app starts here
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // start Firebase
        FirebaseApp.configure()
        print("Firebase configured")

        // match navigation + tab bar style across the app
        setupAppearance()

        // FirebaseManager.shared.authenticatedPing()
        return true
    }

    // same look for nav + tab bars everywhere
    private func setupAppearance() {
        // navigation bar
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(named: "nav.bg") ?? UIColor.systemBackground
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(named: "text.primary") ?? UIColor.label
        ]
        nav.largeTitleTextAttributes = nav.titleTextAttributes

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(named: "tint") ?? UIColor.systemBlue
        UINavigationBar.appearance().prefersLargeTitles = false   // or true if you like that look

        // tab bar
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(named: "nav.bg") ?? UIColor.systemBackground

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = UIColor(named: "tint") ?? UIColor.systemBlue
    }
}
