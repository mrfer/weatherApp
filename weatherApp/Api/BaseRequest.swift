//
//  BaseRequest.swift
//  weatherApp
//
//  Created by Irina on 20.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UIKit

protocol BaseRequest {
    func request(_ callback: @escaping (JSON?, [RequestError]?) -> Void)
}

class RequestError: Error {
    var errorField: String?
    var errorText: String = ""
    
    init(errorField: String?, errorText: String) {
        self.errorField = errorField
        self.errorText = errorText
    }
    
    init(errorText: String) {
        self.errorText = errorText
    }
}

class DFBaseRequest: BaseRequest {
    
    var host = "http://api.openweathermap.org/"
    
    lazy var headers: [String: String] = {
        var innerHeaders: [String:String] = [String:String]()
        
        return innerHeaders
    }()
    
    var parameters: [String: Any] = [String: Any]()
    
    var path = ""
    
    var encoding: ParameterEncoding = URLEncoding.default
    
    func request(_ callback: @escaping (JSON?, [RequestError]?) -> Void) {
    }
    
    func postRequest(_ callback: @escaping (JSON?, [RequestError]?) -> Void) {
        request(with: .post, callback: callback)
    }
    
    func getRequest(_ callback: @escaping (JSON?, [RequestError]?) -> Void) {
        self.request(with: .get, callback: callback)
    }
    
    fileprivate func request(with method: Alamofire.HTTPMethod, callback: @escaping (JSON?, [RequestError]?) -> Void) {
        Alamofire.request(host + path, method: method, parameters: parameters, encoding: encoding)
            .responseJSON { response in
                if let bodyData = response.request?.httpBody {
                    print(String(data: bodyData, encoding: String.Encoding.utf8)!)
                }
                switch response.result {
                case .success(let value):
                    print(String(describing: value))
                    let jsonValue = JSON(value)
                    if jsonValue["error"].int != nil {
                        var requestErrors: [RequestError] = [RequestError]()
                        let errorText = jsonValue["message"].string
                        requestErrors.append(RequestError(errorText: errorText!))
                        callback(nil, requestErrors)
                    } else {
                        callback(jsonValue, nil)
                    }
                case .failure(let error):
                    callback(nil, [RequestError(errorText: error.localizedDescription)])
                }
        }
    }
    
    func upload(for request: URLRequestConvertible, data: Data, callback: @escaping (JSON?, [RequestError]?) -> Void) {
        Alamofire.upload(data, with: request)
            .uploadProgress { progress in
            }
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print(String(describing: value))
                    let jsonValue = JSON(value)
                    if let errors = jsonValue["errors"].dictionary, errors.count > 0 {
                        var requestErrors: [RequestError] = [RequestError]()
                        for (key, error) in errors {
                            requestErrors.append(RequestError(errorField: key, errorText: error.stringValue))
                        }
                        callback(nil, requestErrors)
                    } else {
                        callback(jsonValue, nil)
                    }
                case .failure(let error):
                    callback(nil, [RequestError(errorText: error.localizedDescription)])
                }
        }
    }
}
