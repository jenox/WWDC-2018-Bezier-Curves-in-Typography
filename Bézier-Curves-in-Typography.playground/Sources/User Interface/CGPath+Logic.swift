import CoreGraphics


extension CGPath {

    /// Gets rid of superfluous moves that can be created by assembling a path
    /// from subpaths.
    internal func sanitized() -> CGPath {
        let copy = CGMutablePath()

        self.applyWithBlock({ pointer in
            let element = pointer.pointee

            switch element.type {
            case .moveToPoint:
                copy.move(to: element.points[0])
            case .addLineToPoint:
                copy.addLine(to: element.points[0])
            case .addQuadCurveToPoint:
                copy.addQuadCurve(to: element.points[1], control: element.points[0])
            case .addCurveToPoint:
                copy.addCurve(to: element.points[2], control1: element.points[0], control2: element.points[1])
            case .closeSubpath:
                copy.closeSubpath()
            }
        })

        return copy
    }

    /// Returns a copy of the path created by displacing the point at the given
    /// index by the given offset. If said point is an endpoint to one of the
    /// path's segments, its adjacent control points are also displaced
    /// accordingly.
    internal func displacingPoint(at index: Int, by offset: CGVector) -> CGPath {
        let copy = CGMutablePath()
        var count = 0

        self.applyWithBlock({ pointer in
            let element = pointer.pointee

            switch element.type {
            case .moveToPoint:
                switch index {
                case count: // end point
                    copy.move(to: element.points[0] + offset)
                default: // other point
                    copy.move(to: element.points[0])
                }
                count += 1
            case .addLineToPoint:
                switch index {
                case count: // end point
                    copy.addLine(to: element.points[0] + offset)
                default: // other point
                    copy.addLine(to: element.points[0])
                }
                count += 1
            case .addQuadCurveToPoint:
                switch index {
                case count - 1: // start point
                    copy.addQuadCurve(to: element.points[1], control: element.points[0] + offset)
                case count: // control point
                    copy.addQuadCurve(to: element.points[1], control: element.points[0] + offset)
                case count + 1: // end point
                    copy.addQuadCurve(to: element.points[1] + offset, control: element.points[0] + offset)
                default: // other point
                    copy.addQuadCurve(to: element.points[1], control: element.points[0])
                }
                count += 2
            case .addCurveToPoint:
                switch index {
                case count - 1: // start point
                    copy.addCurve(to: element.points[2], control1: element.points[0] + offset, control2: element.points[1])
                case count: // first control point
                    copy.addCurve(to: element.points[2], control1: element.points[0] + offset, control2: element.points[1])
                case count + 1: // second control point
                    copy.addCurve(to: element.points[2], control1: element.points[0], control2: element.points[1] + offset)
                case count + 2: // end point
                    copy.addCurve(to: element.points[2] + offset, control1: element.points[0], control2: element.points[1] + offset)
                default: // other point
                    copy.addCurve(to: element.points[2], control1: element.points[0], control2: element.points[1])
                }
                count += 3
            case .closeSubpath:
                copy.closeSubpath()
            }
        })

        return copy
    }

    /// The path's end- and control points
    internal var points: [CGPoint] {
        var points: [CGPoint] = []

        self.applyWithBlock({ pointer in
            let element = pointer.pointee

            switch element.type {
            case .moveToPoint:
                points.append(element.points[0])
            case .addLineToPoint:
                points.append(element.points[0])
            case .addQuadCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
            case .addCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
                points.append(element.points[2])
            case .closeSubpath:
                break
            }
        })

        return points
    }

    /// The path's endpoint.
    internal var endpoints: [CGPoint] {
        var points: [CGPoint] = []

        self.applyWithBlock({ pointer in
            let element = pointer.pointee

            switch element.type {
            case .moveToPoint:
                points.append(element.points[0])
            case .addLineToPoint:
                points.append(element.points[0])
            case .addQuadCurveToPoint:
                points.append(element.points[1])
            case .addCurveToPoint:
                points.append(element.points[2])
            case .closeSubpath:
                break
            }
        })

        return points
    }

    /// The path's control points.
    internal var controlPoints: [CGPoint] {
        var points: [CGPoint] = []

        self.applyWithBlock({ pointer in
            let element = pointer.pointee

            switch element.type {
            case .moveToPoint:
                break
            case .addLineToPoint:
                break
            case .addQuadCurveToPoint:
                points.append(element.points[0])
            case .addCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
            case .closeSubpath:
                break
            }
        })

        return points
    }

    /// The path's Bézier curves.
    internal var bezierCurves: [BezierCurve] {
        var first: CGPoint? = nil
        var last: CGPoint? = nil

        var curves: [BezierCurve] = []

        self.applyWithBlock({ pointer in
            let curve: BezierCurve?

            switch pointer.pointee.type {
            case .moveToPoint:
                first = pointer.pointee.points[0]
                last = pointer.pointee.points[0]

                curve = nil
            case .addLineToPoint:
                let start = last!
                let end = pointer.pointee.points[0]

                curve = LinearBezierCurve(from: start, to: end)
            case .addQuadCurveToPoint:
                let start = last!
                let cp = pointer.pointee.points[0]
                let end = pointer.pointee.points[1]

                curve = QuadraticBezierCurve(from: start, to: end, cp: cp)
            case .addCurveToPoint:
                let start = last!
                let cp1 = pointer.pointee.points[0]
                let cp2 = pointer.pointee.points[1]
                let end = pointer.pointee.points[2]

                curve = CubicBezierCurve(from: start, to: end, cp1: cp1, cp2: cp2)
            case .closeSubpath:
                let start = last!
                let end = first!

                curve = LinearBezierCurve(from: start, to: end)
            }

            if let curve = curve {
                last = curve.end

                curves.append(curve)
            }
        })

        return curves
    }
}
