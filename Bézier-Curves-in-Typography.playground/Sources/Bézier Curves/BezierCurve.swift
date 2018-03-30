import CoreGraphics


public protocol BezierCurve {

    // The receiver's start point.
    var start: CGPoint { get }

    // The receiver's end point.
    var end: CGPoint { get }

    // The receiver's control points.
    var controlPoints: [CGPoint] { get }

    /// Returns the point at the given progress along the receiver.
    func point(at progress: CGFloat) -> CGPoint

    /// Returns a transformed version of the receiver.
    func applying(_ transform: CGAffineTransform) -> Self

    /// Appends the receiver to the given mutable path.
    func append(to: CGMutablePath)
}
