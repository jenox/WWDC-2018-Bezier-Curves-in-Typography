import CoreGraphics


public struct QuadraticBezierCurve: BezierCurve {
    public init(from start: CGPoint, to end: CGPoint, cp: CGPoint) {
        self.start = start
        self.end = end
        self.controlPoint = cp
    }

    public var start: CGPoint
    public var end: CGPoint
    public var controlPoint: CGPoint

    public var controlPoints: [CGPoint] {
        return [self.controlPoint]
    }

    public func point(at progress: CGFloat) -> CGPoint {
        let progress = min(max(progress, 0), 1)

        var position = CGVector.zero
        position += 1 * pow(1 - progress, 2) * pow(progress, 0) * CGVector(to: self.start)
        position += 2 * pow(1 - progress, 1) * pow(progress, 1) * CGVector(to: self.controlPoint)
        position += 1 * pow(1 - progress, 0) * pow(progress, 2) * CGVector(to: self.end)

        return position.pointee
    }

    public func applying(_ transform: CGAffineTransform) -> QuadraticBezierCurve {
        var curve = self
        curve.start = curve.start.applying(transform)
        curve.end = curve.end.applying(transform)
        curve.controlPoint = curve.controlPoint.applying(transform)

        return curve
    }

    public func append(to path: CGMutablePath) {
        if path.currentPoint != self.start {
            path.move(to: self.start)
        }

        path.addQuadCurve(to: self.end, control: self.controlPoint)
    }
}
