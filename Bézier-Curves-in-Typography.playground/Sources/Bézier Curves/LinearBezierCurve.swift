import CoreGraphics


public struct LinearBezierCurve: BezierCurve {
    public init(from start: CGPoint, to end: CGPoint) {
        self.start = start
        self.end = end
    }

    public var start: CGPoint
    public var end: CGPoint

    public var controlPoints: [CGPoint] {
        return []
    }

    public func point(at progress: CGFloat) -> CGPoint {
        let progress = min(max(progress, 0), 1)

        let ov = CGVector(to: self.start)
        let vw = CGVector(from: self.start, to: self.end)

        return (ov + progress * vw).pointee
    }

    public func applying(_ transform: CGAffineTransform) -> LinearBezierCurve {
        var curve = self
        curve.start = curve.start.applying(transform)
        curve.end = curve.end.applying(transform)

        return curve
    }

    public func append(to path: CGMutablePath) {
        if path.currentPoint != self.start {
            path.move(to: self.start)
        }

        path.addLine(to: self.end)
    }
}
