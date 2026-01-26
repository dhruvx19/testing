//
//  LiveActivityParams.swift
//  Runner
//
//  Created for Ecliniq
//

import Foundation
import ActivityKit

struct AppointmentAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that updates regularly
        var doctorName: String
        var timeInfo: String
        var expectedTime: String
        var currentToken: Int
        var userToken: Int
        var hospitalName: String
    }

    // Static data that doesn't change
    var appointmentId: String
}
