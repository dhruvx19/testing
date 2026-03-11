//
//  AppointmentLockScreenWidget.swift
//  Runner
//
//  Created for Ecliniq
//  UI matches Android custom_appointment_notification.xml
//

import WidgetKit
import SwiftUI
import ActivityKit
import LiveActivityShared

// MARK: - Colors (exact match to Android XML)
private extension Color {
    /// #424242 — dark text, start & current token circles
    static let notifDark = Color(red: 0.259, green: 0.259, blue: 0.259)
    /// #2372EC — blue: time info, expected time, your-token circle fill
    static let notifBlue = Color(red: 0.137, green: 0.447, blue: 0.925)
    /// #8E8E8E — grey: right progress line, your-token circle border
    static let notifGrey = Color(red: 0.557, green: 0.557, blue: 0.557)
    /// #D9D9D9 — matches Android notification_background.xml solid color
    static let notifBackground = Color(red: 0.851, green: 0.851, blue: 0.851)
}

// MARK: - Widget

struct AppointmentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AppointmentAttributes.self) { context in
            AttachmentLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.doctorName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(context.state.hospitalName)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.timeInfo)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.notifBlue)
                        Text(context.state.expectedTime)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Label("\(context.state.currentToken)", systemImage: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.notifGrey)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.notifGrey)
                        Label("\(context.state.userToken)", systemImage: "person.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.notifBlue)
                    }
                }
            } compactLeading: {
                Text("\(context.state.currentToken)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.notifGrey)
            } compactTrailing: {
                Text("\(context.state.userToken)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.notifBlue)
            } minimal: {
                Text("\(context.state.userToken)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.notifBlue)
            }
        }
    }
}

// MARK: - Lock Screen View

struct AttachmentLockScreenView: View {
    let state: AppointmentAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Row 1: "Your appointment with" + hospital name (logo placeholder)
            HStack {
                Text("Your appointment with")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.notifDark)
                Spacer()
                Image("ecliniq_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 20)
            }

            // Row 2: Doctor name + time info inline
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(state.doctorName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.notifDark)
                    .lineLimit(1)
                if !state.timeInfo.isEmpty {
                    Text(state.timeInfo)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.notifBlue)
                        .lineLimit(1)
                }
            }
            .padding(.top, 2)

            // Row 3: Expected time
            Text("Expected Time: \(state.expectedTime)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.notifBlue)
                .padding(.top, 0)

            // Row 4: Token progress bar
            TokenProgressView(
                currentToken: state.currentToken,
                userToken: state.userToken
            )
            .padding(.top, 9)
        }
        .padding(14)
        .activityBackgroundTint(.notifBackground)
        .padding(.horizontal, 9)
    }
}

// MARK: - Token Progress Bar

/// Matches Android RelativeLayout progress section:
/// [S]——white line——[current]——grey line——[your no]
struct TokenProgressView: View {
    let currentToken: Int
    let userToken: Int

    private let circleSize: CGFloat = 32
    private let lineHeight: CGFloat = 4

    /// 0…1: how far along the queue we are
    private var progress: CGFloat {
        guard userToken > 0 else { return 0 }
        return min(max(CGFloat(currentToken) / CGFloat(userToken), 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // Left edge X of each circle
            let startLeft: CGFloat = 0
            let endLeft: CGFloat = w - circleSize
            let currentLeft: CGFloat = (endLeft - startLeft) * progress

            // Line runs between circle centres
            let startCenter = startLeft + circleSize / 2
            let currentCenter = currentLeft + circleSize / 2
            let endCenter = endLeft + circleSize / 2
            let lineMidY = circleSize / 2 - lineHeight / 2

            ZStack(alignment: .topLeading) {

                // White line: Start → Current (progress made)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: max(currentCenter - startCenter, 0), height: lineHeight)
                    .offset(x: startCenter, y: lineMidY)

                // Grey line: Current → Your No (remaining queue)
                Rectangle()
                    .fill(Color.notifGrey)
                    .frame(width: max(endCenter - currentCenter, 0), height: lineHeight)
                    .offset(x: currentCenter, y: lineMidY)

                // Start "S" circle — white border, dark fill
                TokenCircleView(text: "S", borderColor: .white, fillColor: .notifDark)
                    .offset(x: startLeft, y: 0)

                // Current token circle — white border, dark fill
                TokenCircleView(text: "\(currentToken)", borderColor: .white, fillColor: .notifDark)
                    .offset(x: currentLeft, y: 0)

                // Your token circle — grey border, blue fill
                TokenCircleView(text: "\(userToken)", borderColor: .notifGrey, fillColor: .notifBlue)
                    .offset(x: endLeft, y: 0)

                // Labels below circles
                Text("Start")
                    .labelStyle(width: circleSize, xOffset: startLeft)

                Text("Current")
                    .labelStyle(width: 54, xOffset: currentLeft - 11)

                Text("Your No.")
                    .labelStyle(width: circleSize, xOffset: endLeft)
            }
        }
        .frame(height: circleSize + 20 + 4) // circle + label + gap
    }
}

// MARK: - Token Circle

struct TokenCircleView: View {
    let text: String
    let borderColor: Color
    let fillColor: Color

    var body: some View {
        ZStack {
            Circle().fill(borderColor)
            Circle().fill(fillColor).padding(3)
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Label helper

private extension Text {
    func labelStyle(width: CGFloat, xOffset: CGFloat) -> some View {
        self
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.notifDark)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(width: width, alignment: .center)
            .offset(x: xOffset, y: 36)
    }
}