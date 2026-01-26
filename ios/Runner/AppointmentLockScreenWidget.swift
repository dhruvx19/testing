//
//  AppointmentLockScreenWidget.swift
//  Runner
//
//  Created for Ecliniq
//  NOTE: This file contains the SwiftUI code for the Widget Extension.
//  You must create a Widget Extension target in Xcode and copy this code there.
//  Also ensure LiveActivityParams.swift is included in the Extension target.
//

import WidgetKit
import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct AppointmentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AppointmentAttributes.self) { context in
            // Lock Screen / Banner UI
            AttachmentLockScreenView(state: context.state)
        } dynamicIsland: { context in
            // Dynamic Island UI (iPhone 14 Pro+)
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("\(context.state.currentToken)")
                            .font(.headline)
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text("\(context.state.userToken)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    } icon: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.doctorName)
                        .font(.headline)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                         Text(context.state.timeInfo)
                        Spacer()
                        Text("Exp: \(context.state.expectedTime)")
                    }
                }
            } compactLeading: {
                Text("\(context.state.currentToken)")
                    .foregroundColor(.white)
            } compactTrailing: {
                Text("\(context.state.userToken)")
                    .foregroundColor(.blue)
            } minimal: {
                Text("\(context.state.userToken)")
                    .foregroundColor(.blue)
            }
        }
    }
}

@available(iOS 16.1, *)
struct AttachmentLockScreenView: View {
    let state: AppointmentAttributes.ContentState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.hospitalName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("LIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            }
            
            Text("Appointment with \(state.doctorName)")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(state.timeInfo) // "Arriving in 8 min"
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text("Expected: \(state.expectedTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Progress Bar Visualization
            HStack(alignment: .center, spacing: 5) {
                // Start
                Image(systemName: "house.fill")
                    .foregroundColor(.gray)
                
                // Line
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                
                // Current Token
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 24, height: 24)
                        Text("\(state.currentToken)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Line
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                
                // User Token
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                        Text("\(state.userToken)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("You")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                // Line (Future)
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .activityBackgroundTint(Color.white)
    }
}
