import Foundation
import CoreGraphics

struct SpeedTracker {
    private let speedWindowSize = 8
    private let maximumPlausibleSpeed = 25.0

    private var previousLeftWrist: CGPoint?
    private var previousRightWrist: CGPoint?
    private var previousSpeedTimestamp: TimeInterval?
    private var recentLeftSpeeds: [Double] = []
    private var recentRightSpeeds: [Double] = []
    private var speedTrackingHadActivePunch = false

    mutating func update(
        leftWrist: CGPoint,
        rightWrist: CGPoint,
        shoulderWidth: CGFloat,
        timestamp: TimeInterval
    ) {
        defer {
            previousLeftWrist = leftWrist
            previousRightWrist = rightWrist
            previousSpeedTimestamp = timestamp
        }

        guard let previousLeftWrist,
              let previousRightWrist,
              let previousSpeedTimestamp else {
            return
        }

        let deltaTime = timestamp - previousSpeedTimestamp
        guard deltaTime > 0.001, deltaTime < 0.25 else { return }

        let leftSpeed = plausibleSpeed(
            Double(WorkoutMath.distance(leftWrist, previousLeftWrist) / shoulderWidth)
                / deltaTime
        )
        let rightSpeed = plausibleSpeed(
            Double(WorkoutMath.distance(rightWrist, previousRightWrist) / shoulderWidth)
                / deltaTime
        )

        appendRolling(leftSpeed, to: &recentLeftSpeeds)
        appendRolling(rightSpeed, to: &recentRightSpeeds)
    }

    func speedForPunch(_ punch: PunchType, stance: Stance) -> Double? {
        guard punch != .none else { return nil }

        let usesLeftHand: Bool

        switch (stance, punch) {
        case (.orthodox, .jab), (.southpaw, .cross):
            usesLeftHand = true
        case (.orthodox, .cross), (.southpaw, .jab):
            usesLeftHand = false
        case (_, .none):
            return nil
        }

        return usesLeftHand
            ? recentLeftSpeeds.max()
            : recentRightSpeeds.max()
    }

    mutating func resetWindow(after punch: PunchType) {
        if punch != .none {
            speedTrackingHadActivePunch = true
            return
        }

        guard speedTrackingHadActivePunch else { return }
        speedTrackingHadActivePunch = false
        recentLeftSpeeds.removeAll(keepingCapacity: true)
        recentRightSpeeds.removeAll(keepingCapacity: true)
    }

    mutating func reset() {
        previousLeftWrist = nil
        previousRightWrist = nil
        previousSpeedTimestamp = nil
        recentLeftSpeeds.removeAll(keepingCapacity: true)
        recentRightSpeeds.removeAll(keepingCapacity: true)
        speedTrackingHadActivePunch = false
    }

    private func plausibleSpeed(_ speed: Double) -> Double {
        guard speed.isFinite,
              speed >= 0,
              speed <= maximumPlausibleSpeed else {
            return 0
        }
        return speed
    }

    private func appendRolling(_ value: Double, to values: inout [Double]) {
        values.append(value)
        if values.count > speedWindowSize {
            values.removeFirst(values.count - speedWindowSize)
        }
    }
}