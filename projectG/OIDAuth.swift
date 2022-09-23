//
//  OIDAuth.swift
//  projectG
//
//  Created by root0 on 2022/09/20.
//

import Foundation
import AppAuth

class OIDAuth: NSObject, OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        self.stateChanged()
    }
    // OpenIDConnect - Google
    
    private let kIssuer: String = "https://accounts.google.com"
    private let kClientID: String? = "780002601256-cutm2pjlacfkohi57uer6j73kkinbvbh.apps.googleusercontent.com"
    private let kRedirectURI: String = "com.googleusercontent.apps.780002601256-cutm2pjlacfkohi57uer6j73kkinbvbh:/google"
    
    private var authState: OIDAuthState?
    private var config: OIDServiceConfiguration?
    
    static let shared: OIDAuth = {
        let ins = OIDAuth()
        // additional setup code
        ins.loadState()
        return ins
    }()
    
    
    // MARK: Change State - SAVE & LOAD
    private func saveState() {
        var data: Data? = nil

        if let authState = self.authState {
//            data = NSKeyedArchiver.archivedData(withRootObject: authState)
            data = try? NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
        }
        
        if let userDefaults = UserDefaults(suiteName: "group.net.openid.appauth.Example") {
            userDefaults.set(data, forKey: kAppAuthExampleAuthStateKey)
            userDefaults.synchronize()
        }
    }
    
    private func loadState() {
        guard let data = UserDefaults(suiteName: "group.net.openid.appauth.Example")?.object(forKey: kAppAuthExampleAuthStateKey) as? Data else {
            return
        }
        
        if let authState = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [OIDAuthState.self], from: data) as? OIDAuthState {
            self.setAuthState(authState)
        }
    }
    
    private func setAuthState(_ authState: OIDAuthState?) {
        if (self.authState == authState) {
            return;
        }
        self.authState = authState;
        self.authState?.stateChangeDelegate = self;
        self.stateChanged()
    }
    
    func stateChanged() {
        saveState()
    }
    
    
    func discoverAuthConfiguraiton() {
        guard let issuer = URL(string: kIssuer) else { return }
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let config = configuration else {
                self.setAuthState(nil)
                return
            }
            
            print("DISCOVER CONFIGURATION", config)
            
            // register Client OR doAuth
        }
    }
    
    func doAuthWithCodeExchange(config: OIDServiceConfiguration?, clientID: String?) {
        guard let config = config else { return }
        if let clientID = clientID {
            
            guard let redirectURI = URL(string: kRedirectURI) else { return }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            
            // MARK:
            let request = OIDAuthorizationRequest(configuration: config,
                                                  clientId: clientID,
                                                  scopes: [OIDScopeOpenID, "https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/cloud-translation"],
                                                  redirectURL: redirectURI,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)
            
            appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                          presenting: ViewController(), callback: { authState, error in
                if let authState = authState {
                    self.setAuthState(authState)
                    print("Got authorization tokens. Access token:", authState.lastTokenResponse?.accessToken ?? "DEFAULT")
                } else {
                    self.setAuthState(nil)
                }
            })
            
        } else {
            
        }
    }
    
}
