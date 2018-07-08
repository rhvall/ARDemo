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
            return "👀 Find a plane with some coffee"
        case .ready:
            return "☕️ Tap to drink"
        case .temporarilyUnavailable:
            return "😱 Adjusting caffeine levels. Please wait"
        case .failed:
            return "⛔️ Caffeine crisis! Please restart App."
        }
    }
}
