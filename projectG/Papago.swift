//
//  Papago.swift
//  projectG
//
//  Created by root0 on 2022/09/02.
//

import Foundation
import Alamofire
import SwiftyJSON

class Papago {
    static let shared = Papago()
    fileprivate let ClientID = "A6UDV4T4UGBF_af457GJ"
    fileprivate let ClientSecret = "CsFzYqs9V8"
    
    let transURLs = "https://openapi.naver.com/v1/papago/n2mt"
    let detectURLs = "https://openapi.naver.com/v1/papago/detectLangs"
    
    let papago_header: HTTPHeaders = [
        "Content-Type" : "application/x-www-form-urlencoded; charset=UTF-8",
        "X-Naver-Client-Id" : "A6UDV4T4UGBF_af457GJ",
        "X-Naver-Client-Secret" : "CsFzYqs9V8"
    ]
    
    
    
    func translator(text: String, _ completion: ((String) -> Void)? = nil) {
        let param = [
            "source" : "ko",
            "target" : "en",
            "text" : text
        ]
        
//        _ = AF.request(transURLs, method: .post, parameters: param, headers: papago_header).responseDecodable(of: ) { response in
//
//        }
        
        var result = ""
        AF.request(transURLs, method: .post, parameters: param, headers: papago_header).responseJSON { response in
            
            switch response.result {
            case .success(let data):
                let jsondata = JSON(data)
                print(jsondata["message"]["result"]["translatedText"])
                result = jsondata["message"]["result"]["translatedText"].stringValue
                if let completion = completion {
                    completion(result)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
}

class TransResponse: Codable {
    var message: TransResponseData?
    
    enum Codingkeys: String, CodingKey {
        case message
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Codingkeys.self)
        message = try container.decode(TransResponseData.self, forKey: .message)
    }
}

struct TransResponseData: Codable {
    var type: String
    var service: String
    var version: String
    var result: TransResult
    
    enum CodingKeysData: String, CodingKey {
        case type = "@type"
        case service = "@service"
        case version = "@version"
        case result
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeysData.self)
        type = try container.decode(String.self, forKey: .type)
        service = try container.decode(String.self, forKey: .service)
        version = try container.decode(String.self, forKey: .version)
        result = try container.decode(TransResult.self, forKey: .result)
    }
}

struct TransResult: Codable {
    var srcLangType: String
    var tarLangType: String
    var translatedText: String
    
    enum CodingKeys: String, CodingKey {
        case srcLangType
        case tarLangType
        case translatedText
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        srcLangType = try container.decode(String.self, forKey: .srcLangType)
        tarLangType = try container.decode(String.self, forKey: .tarLangType)
        translatedText = try container.decode(String.self, forKey: .translatedText)
    }
}
