//
//  STTViewModel.swift
//  projectG
//
//  Created by root0 on 2022/09/15.
//

import Foundation
import RxSwift
import RxCocoa

import Alamofire
import SwiftyJSON

protocol ViewModelType {
    associatedtype Inputs
    associatedtype Outputs
    
    func transform(input: Inputs) -> Outputs
}

final class STTViewModel: ViewModelType {
    
    struct Inputs {
        let recordOpenBtn_tap: Observable<Void>
        let recordBtn_tap: Observable<Void>
    }
    
    struct Outputs {
        var openRecording: Driver<Void>
        var recordAction: Driver<Void>
    }
    
    var speechScript: Driver<String>
    var recordBtnTitle: Driver<String>
    var translatedText: Driver<String>
    
    var sttModel = STTModel()
    let dBag = DisposeBag()
    
    var speech: SpeechManager!
    
    init() {
        
        speechScript = sttModel.speechScript
            .distinctUntilChanged()
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        recordBtnTitle = sttModel.recordBtnTitle
            .distinctUntilChanged()
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        translatedText = sttModel.translatedText
            .distinctUntilChanged()
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        sttModel.speechScript
            .bind { asdf in
                self.gtv3(token: nil, text: asdf)
            }.disposed(by: dBag)
        
        speech = SpeechManager(sttModel)
        
        
    }
    
    func transform(input: Inputs) -> Outputs {
        
        let openRecording = input.recordOpenBtn_tap
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        let recording = input.recordBtn_tap
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        return Outputs(openRecording: openRecording, recordAction: recording)
    }
    
}

extension STTViewModel {
    
    func gtv3(token: String? = nil, text: String? = nil) {
        var token = token
        if token == nil {
            token = UserDefaults.standard.string(forKey: "userGID_AccessToken") ?? "DEFAULT"
        }
        let text = text ?? "안녕하세요 오늘 출근했어요"
        let param: [String : Any] = [
            "contents" : text,
            "targetLanguageCode" : "en",
            "mimeType" : "text/plain"
        ]
        let header_gt: HTTPHeaders = [
            "Content-Type" : "application/x-www-form-urlencoded; charset=utf-8",
            "Authorization" : "Bearer \(token ?? "Default_Token")"
        ]
        
        AF.request("https://translate.googleapis.com/v3/projects/780002601256:translateText", method: .post, parameters: param, headers: header_gt).responseJSON { response in
            switch response.result {
            case .success(let data):
                let jsonData = JSON(data)
                print(jsonData)
                //self.translatedTextView.text = jsonData["translations"][0]["translatedText"].stringValue
                self.sttModel.translatedText.accept(jsonData["translations"][0]["translatedText"].stringValue)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}
