//
//  CardinalDirection.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 28.01.2022.
//

import Foundation

enum CardinalDirection: String, CaseIterable {
    case n = "North"
    case nne = "North-Northeast"
    case ne = "Northeast"
    case ene = "East-Northeast"
    case e = "East"
    case ese = "East-Southeast"
    case se = "Southeast"
    case sse = "South-Southeast"
    case s = "South"
    case ssw = "South-Southwest"
    case sw = "Southwest"
    case wsw = "West-Southwest"
    case w = "West"
    case wnw = "West-Northwest"
    case nw = "Northwest"
    case nnw = "North-Northwest"
}

extension CardinalDirection {
    
    enum DirectionError: Error { case invalidWindDirection }
    
    
    init(degrees: Double) throws {
        switch degrees {
        case 0.0:
            self = .n
        case 22.5:
            self = .nne
        case 45.0:
            self = .ne
        case 67.5:
            self = .ene
        case 90.0:
            self = .e
        case 112.5:
            self = .ese
        case 135.0:
            self = .se
        case 157.5:
            self = .sse
        case 180.0:
            self = .s
        case 202.5:
            self = .ssw
        case 225.0:
            self = .sw
        case 247.5:
            self = .wsw
        case 270.0:
            self = .w
        case 292.5:
            self = .wnw
        case 315.0:
            self = .nw
        case 337.5:
            self = .nnw
        default:
            throw DirectionError.invalidWindDirection
        }
    }
}
