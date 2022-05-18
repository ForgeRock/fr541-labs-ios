//
//  ForceAuthInterceptor.swift
//  tutorial
//
//  Created by Geza Simon on 2022. 05. 03..
//

import Foundation
import FRCore

class ForceAuthInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        if (action.type == "START_AUTHENTICATE" ), //MARK SELFSERVICE: action
            let payload = action.payload,
            let treeName = payload["tree"] as? String, //MARK SELFSERVICE: tree
            treeName == "fr541-password-ios"  //MARK SELFSERVICE: treename
        {
            var urlParams = request.urlParams
            urlParams["ForceAuth"] = "true"  //MARK SELFSERVICE: param
            let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
            return newRequest
        }
        else {
            return request
        }
    }

}
