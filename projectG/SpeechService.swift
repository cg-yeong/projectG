//
//  SpeechService.swift
//  projectG
//
//  Created by root0 on 2022/09/14.
//

import Foundation
import Speech
import UIKit

class SpeechService: NSObject, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer.init(locale: .init(identifier: "ko-KR"))
    override init() {
        
    }
    
    convenience init(delegate ob: UIViewController) {
        self.init()
        speechRecognizer?.delegate = ob as? SFSpeechRecognizerDelegate
        
    }
    
}
