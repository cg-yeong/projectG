//
//  AppDelegate.swift
//  projectG
//
//  Created by root0 on 2022/09/01.
//

import UIKit
import GoogleSignIn
import AppAuth
import OAuthSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let signInConfig = GIDConfiguration(clientID: "780002601256-cutm2pjlacfkohi57uer6j73kkinbvbh.apps.googleusercontent.com")
    /// AppAuth
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let engine = UserDefaults.standard.string(forKey: "whatEngine")
        if engine == "0" {
            print("previous engine is naver")
        } else if engine == "1" {
            print("previous engine is google")
        }
        
        // Override point for customization after application launch.
        if launchOptions?[.sourceApplication] as? String == "com.apple.SafariViewService" {
            
        }
        SwiftGoogleTranslate.shared.start(with: "API_KEY")
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                // show the app's signed-out state
                print("no user")
            } else {
                // sign in state
                print("step signin")
                
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled: Bool
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        
        if url.host == "oauth-callback" {
            OAuthSwift.handle(url: url)
            return true
        }

        if let authorizationFlow = currentAuthorizationFlow, authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        
        return false
    }

}

