//
//  DLARSessionState.swift
//  ARKitPlanesAndObjects
//
//  Created by Ignacio Nieto Carvajal on 13/11/2017.
//  Copyright © 2017 Digital Leaves. All rights reserved.
//

import Foundation

enum ARCoffeeSessionState: String, CustomStringConvertible {
    case initialized = "initialized"
    case ready = "ready"
    case temporarilyUnavailable = "temporarily unavailable"
    case failed = "failed"

    var description: String {
        switch self {
        case .initialized:
            return "👀 Find a plane"
        case .ready:
            return "Explore the 🏘"
        case .temporarilyUnavailable:
            return "😱 Adjusting levels. Please wait"
        case .failed:
            return "⛔️ crisis! Please restart App."
        }
    }
}
