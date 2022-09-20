//
//  OIDAuth.swift
//  projectG
//
//  Created by root0 on 2022/09/20.
//

import Foundation
import AppAuth

class OIDAuth: NSObject { // OpenIDConnect - Google
    
    private let kIssuer: String = "https://accounts.google.com"
    private let kClientID: String = "780002601256-cutm2pjlacfkohi57uer6j73kkinbvbh.apps.googleusercontent.com"
    private let kRedirectURI: String = "com.googleusercontent.apps.780002601256-cutm2pjlacfkohi57uer6j73kkinbvbh:/google"
    
    static let shared: OIDAuth = {
        let ins = OIDAuth()
        // additional setup code
        return ins
    }()
    
}
