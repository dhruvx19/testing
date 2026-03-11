//
//  LiveActivityService.swift
//  Runner
//
//  Created for Ecliniq
//

import Foundation
import ActivityKit
import LiveActivityShared

@available(iOS 16.2, *)
class LiveActivityService {
    static let shared = LiveActivityService()
    
    private var currentActivity: Activity<AppointmentAttributes>?
    
    func start(
        appointmentId: String,
        doctorName: String,
        timeInfo: String,
        expectedTime: String,
        currentToken: Int,
        userToken: Int,
        hospitalName: String
    ) {
        Task {
            // End all existing activities first (await to avoid concurrent activity limit)
            for activity in Activity<AppointmentAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
                print("🧹 Ended stale activity: \(activity.id)")
            }
            currentActivity = nil

            let attributes = AppointmentAttributes(appointmentId: appointmentId)
            let contentState = AppointmentAttributes.ContentState(
                doctorName: doctorName,
                timeInfo: timeInfo,
                expectedTime: expectedTime,
                currentToken: currentToken,
                userToken: userToken,
                hospitalName: hospitalName
            )

            let authInfo = ActivityAuthorizationInfo()
            print("🔍 Live Activities enabled: \(authInfo.areActivitiesEnabled)")
            print("🔍 Frequent updates enabled: \(authInfo.frequentPushesEnabled)")
            print("🔍 Activity type: \(String(reflecting: AppointmentAttributes.self))")

            do {
                let activity = try Activity<AppointmentAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil)
                )
                currentActivity = activity
                print("✅ Live Activity started: \(activity.id)")
                print("🔍 Activity state: \(activity.activityState)")
            } catch {
                print("❌ Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    func update(
        doctorName: String,
        timeInfo: String,
        expectedTime: String,
        currentToken: Int,
        userToken: Int,
        hospitalName: String
    ) {
        guard let activity = currentActivity else {
            print("No active Live Activity to update")
            return
        }
        
        let updatedContentState = AppointmentAttributes.ContentState(
            doctorName: doctorName,
            timeInfo: timeInfo,
            expectedTime: expectedTime,
            currentToken: currentToken,
            userToken: userToken,
            hospitalName: hospitalName
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedContentState, staleDate: nil)
            )
            print("Live Activity updated")
        }
    }
    
    func end() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            print("Live Activity ended")
            currentActivity = nil
        }
    }
}
