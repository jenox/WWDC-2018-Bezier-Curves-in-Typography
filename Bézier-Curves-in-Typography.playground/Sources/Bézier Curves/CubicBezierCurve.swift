import CoreGraphics


public struct CubicBezierCurve: BezierCurve {
    public init(from start: CGPoint, to end: CGPoint, cp1: CGPoint, cp2: CGPoint) {
        self.start = start
        self.end = end
        self.controlPoint1 = cp1
        self.controlPoint2 = cp2
    }

    public var start: CGPoint
    public var end: CGPoint
    public var controlPoint1: CGPoint
    public var controlPoint2: CGPoint

    public var controlPoints: [CGPoint] {
        return [self.controlPoint1, self.controlPoint2]
    }

    public func point(at progress: CGFloat) -> CGPoint {
        let progress = min(max(progress, 0), 1)

        var position = CGVector.zero
        position += 1 * pow(1 - progress, 3) * pow(progress, 0) * CGVector(to: self.start)
        position += 3 * pow(1 - progress, 2) * pow(progress, 1) * CGVector(to: self.controlPoint1)
        position += 3 * pow(1 - progress, 1) * pow(progress, 2) * CGVector(to: self.controlPoint2)
        position += 1 * pow(1 - progress, 0) * pow(progress, 3) * CGVector(to: self.end)

        return position.pointee
    }

    public func applying(_ transform: CGAffineTransform) -> CubicBezierCurve {
        var curve = self
        curve.start = curve.start.applying(transform)
        curve.end = curve.end.applying(transform)
        curve.controlPoint1 = curve.controlPoint1.applying(transform)
        curve.controlPoint2 = curve.controlPoint2.applying(transform)

        return curve
    }

    public func append(to path: CGMutablePath) {
        if path.currentPoint != self.start {
            path.move(to: self.start)
        }

        path.addCurve(to: self.end, control1: self.controlPoint1, control2: self.controlPoint2)
    }
}
