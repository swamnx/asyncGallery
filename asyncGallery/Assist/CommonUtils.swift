//
//  CommonUtils.swift
//  asyncGallery
//
//  Created by swamnx on 31.05.21.
//

import Foundation

struct CommonUtils {
    
    static var shared = CommonUtils()
    
    func getHttpsValue(httpValue value: String) -> String {
        var httpsValue = value
        httpsValue.insert("s", at: httpsValue.index(httpsValue.startIndex, offsetBy: 4))
        return httpsValue
    }
}
