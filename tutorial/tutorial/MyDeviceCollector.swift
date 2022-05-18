//
//  MyDeviceCollector.swift
//  tutorial
//
//  Created by Geza Simon on 2022. 05. 04..
//


//DONE CUSTOMDEVICE

import Foundation
import FRCore
import FRAuth

class MyDeviceCollector: DeviceCollector {
    var name: String = "custom"

    func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]

        // Perform logic to collect any device profile
        result["iosapp"] = "com.example.tutorial"

        completion(result)
    }
}
