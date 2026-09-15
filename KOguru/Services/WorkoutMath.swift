import Foundation
import CoreGraphics

enum WorkoutMath {
    static func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    static func clamp(
        _ value: CGFloat,
        min minimum: CGFloat,
        max maximum: CGFloat
    ) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    static func jointAngle(
        _ first: CGPoint,
        _ middle: CGPoint,
        _ last: CGPoint
    ) -> CGFloat {
        let firstVector = CGVector(
            dx: first.x - middle.x,
            dy: first.y - middle.y
        )
        let secondVector = CGVector(
            dx: last.x - middle.x,
            dy: last.y - middle.y
        )
        let dotProduct = firstVector.dx * secondVector.dx
            + firstVector.dy * secondVector.dy
        let firstMagnitude = hypot(firstVector.dx, firstVector.dy)
        let secondMagnitude = hypot(secondVector.dx, secondVector.dy)

        guard firstMagnitude > 0, secondMagnitude > 0 else { return 0 }

        let cosine = clamp(
            dotProduct / (firstMagnitude * secondMagnitude),
            min: -1,
            max: 1
        )
        return acos(cosine) * 180 / .pi
    }
}