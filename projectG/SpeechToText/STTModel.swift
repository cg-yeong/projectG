//
//  STTModel.swift
//  projectG
//
//  Created by root0 on 2022/09/15.
//

import Foundation
import RxSwift
import RxCocoa

class STTModel {
    
    var speechScript: BehaviorRelay<String> = .init(value: "")
    var translatedText: BehaviorRelay<String> = .init(value: "")
    var recordBtnTitle: BehaviorRelay<String> = .init(value: "말하기 시작")
}
