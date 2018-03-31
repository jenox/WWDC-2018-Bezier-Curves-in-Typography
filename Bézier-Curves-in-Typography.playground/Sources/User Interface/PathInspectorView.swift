import AppKit


public class PathInspectorView: NSView {

    // MARK: - Initialization

    public override init(frame: CGRect) {
        self.strokeColor = NSColor.black
        self.fillColor = NSColor.stripes(width: 2, height: 2, color: .black, alpha: 0.2)
        self.fillRule = .winding
        self.highlightColor = NSColor(calibratedRed: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)

        super.init(frame: frame)

        self.reloadCenteringTransformIfNeeded()
    }

    public convenience init(frame: CGRect, path: CGPath) {
        self.init(frame: frame)

        defer {
            self.path = path
        }
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }



    // MARK: - Configuration

    /// The path to be inspected.
    public var path: CGPath? = nil {
        didSet {
            self.committedPath = self.path?.sanitized()

            self.reloadNormalizingTransformIfNeeded()
        }
    }

    /// The transform to be applied to the path.
    public var transform: CGAffineTransform = .identity {
        didSet { self.currentUserTransform = self.transform }
    }

    /// The color used to stroke the path.
    public var strokeColor: NSColor {
        didSet { self.setNeedsDisplay() }
    }

    /// The color used to fill the path.
    public var fillColor: NSColor {
        didSet { self.setNeedsDisplay() }
    }

    /// The fill rule used to fill the path.
    public var fillRule: CGPathFillRule {
        didSet { self.setNeedsDisplay() }
    }

    /// The color used to highlight portions of the path.
    public var highlightColor: NSColor {
        didSet { self.setNeedsDisplay() }
    }



    // MARK: - View Dimensions

    public override var bounds: CGRect {
        didSet { self.reloadCenteringTransformIfNeeded() }
    }

    public override var frame: CGRect {
        didSet { self.reloadCenteringTransformIfNeeded() }
    }

    public override func setFrameSize(_ size: CGSize) {
        super.setFrameSize(size)

        self.reloadCenteringTransformIfNeeded()
    }

    public override func setBoundsSize(_ size: CGSize) {
        super.setBoundsSize(size)

        self.reloadCenteringTransformIfNeeded()
    }



    // MARK: - Transformation

    fileprivate var centeringTransform: CGAffineTransform = .identity {
        didSet { self.reloadEffectiveTransformIfNeeded() }
    }

    fileprivate var currentUserTransform: CGAffineTransform = .identity {
        didSet { self.reloadEffectiveTransformIfNeeded() }
    }

    fileprivate var normalizingTransform: CGAffineTransform = .identity {
        didSet { self.reloadEffectiveTransformIfNeeded() }
    }

    fileprivate var effectiveTransform: CGAffineTransform = .identity {
        didSet { self.setNeedsDisplay() }
    }

    fileprivate func reloadCenteringTransformIfNeeded() {
        let bounds = CGRect(origin: .zero, size: self.bounds.size)

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: bounds.midX, y: bounds.midY)
        transform = transform.scaledBy(x: +1, y: -1)

        if self.centeringTransform != transform {
            self.centeringTransform = transform
        }
    }

    fileprivate func reloadNormalizingTransformIfNeeded() {
        var transform = CGAffineTransform.identity

        if let path = self.path {
            let bounds = CGRect(origin: .zero, size: self.bounds.size)
            let boundingBox = path.boundingBox

            if !bounds.isEmpty && !boundingBox.isEmpty {
                let sx = bounds.width / boundingBox.width
                let sy = bounds.height / boundingBox.height
                let scale = 0.9 * fmin(sx, sy)

                transform = transform.scaledBy(x: scale, y: scale)
                transform = transform.translatedBy(x: -boundingBox.midX, y: -boundingBox.midY)
            }
        }

        if self.normalizingTransform != transform {
            self.normalizingTransform = transform
        }
    }

    private func reloadEffectiveTransformIfNeeded() {
        var transform = CGAffineTransform.identity
        transform = transform.concatenating(self.normalizingTransform)
        transform = transform.concatenating(self.currentUserTransform)
        transform = transform.concatenating(self.centeringTransform)

        if self.effectiveTransform != transform {
            self.effectiveTransform = transform
        }
    }



    // MARK: - Paths

    fileprivate var committedPath: CGPath? = nil {
        didSet {
            self.currentPath = self.committedPath
            self.state = .idle
        }
    }

    fileprivate var currentPath: CGPath? = nil {
        didSet {
            self.updateHoveredPointIndexIfNeeded()
            self.setNeedsDisplay(.infinite)
        }
    }



    // MARK: - Geometry

    public override var isFlipped: Bool {
        return true
    }

    public override var wantsLayer: Bool {
        get { return true }
        set {}
    }



    // MARK: - Rendering

    public override func draw(_ rect: CGRect) {
        let context = NSGraphicsContext.current!.cgContext
        context.setFillColor(NSColor.white.cgColor)
        context.fill(rect)

        if let path = self.currentPath {
            self.draw(path.applying(self.effectiveTransform))
        }
    }

    private func draw(_ path: CGPath) {
        let context = NSGraphicsContext.current!.cgContext
        context.setLineWidth(1)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let endpoints = path.endpoints
        let controlPoints = path.controlPoints
        let hoveredOrDraggedPoint: CGPoint?

        if case .dragging(let index, _) = self.state {
            hoveredOrDraggedPoint = path.points[index]
        }
        else if let index = self.hoveredPointIndex {
            hoveredOrDraggedPoint = path.points[index]
        }
        else {
            hoveredOrDraggedPoint = nil
        }

        self.fill(path)
        self.stroke(path)
        context.saveGState()
        self.clip(to: path.controlPoints, invert: true)
        self.strokeHelpers(of: path)
        context.restoreGState()

        for point in endpoints {
            if point == hoveredOrDraggedPoint {
                self.mark(point, stroke: self.strokeColor, fill: self.highlightColor)
            }
            else {
                self.mark(point, stroke: self.strokeColor, fill: .white)
            }
        }

        for point in controlPoints {
            if point == hoveredOrDraggedPoint {
                self.mark(point, stroke: self.strokeColor, fill: self.highlightColor)
            }
            else {
                self.mark(point, stroke: self.strokeColor.withAlphaComponent(0.2), fill: .clear)
            }
        }
    }

    private func fill(_ path: CGPath) {
        let context = NSGraphicsContext.current!.cgContext
        context.beginPath()
        context.addPath(path)
        context.setFillColor(self.fillColor.cgColor)
        context.fillPath(using: self.fillRule)
    }

    private func stroke(_ source: CGPath) {
        let path = CGMutablePath()

        for curve in source.bezierCurves {
            curve.append(to: path)
        }

        let context = NSGraphicsContext.current!.cgContext
        context.beginPath()
        context.addPath(path)
        context.setStrokeColor(self.strokeColor.cgColor)
        context.strokePath()
    }

    private func strokeHelpers(of source: CGPath) {
        let path = CGMutablePath()

        for curve in source.bezierCurves {
            guard !curve.controlPoints.isEmpty else { continue }

            if path.currentPoint != curve.start {
                path.move(to: curve.start)
            }

            for x in curve.controlPoints {
                path.addLine(to: x)
            }

            path.addLine(to: curve.end)
        }

        let context = NSGraphicsContext.current!.cgContext
        context.beginPath()
        context.addPath(path)
        context.setStrokeColor(self.strokeColor.withAlphaComponent(0.15).cgColor)
        context.strokePath()
    }

    private func clip(to points: [CGPoint], invert: Bool) {
        let context = NSGraphicsContext.current!.cgContext
        context.beginPath()

        for point in points {
            context.addPath(self.marker(for: point))
        }

        if invert {
            context.addRect(.infinite)
            context.clip(using: .evenOdd)
        }
        else {
            context.clip()
        }
    }

    private func mark(_ point: CGPoint, stroke: NSColor, fill: NSColor) {
        let context = NSGraphicsContext.current!.cgContext

        context.beginPath()
        context.addPath(self.marker(for: point))
        context.setFillColor(fill.cgColor)
        context.setStrokeColor(stroke.cgColor)
        context.drawPath(using: .fillStroke)
    }

    private func marker(for point: CGPoint) -> CGPath {
        let width = 8 as CGFloat
        let bounds = CGRect(x: point.x - width / 2, y: point.y - width / 2, width: width, height: width)

        return CGPath(ellipseIn: bounds, transform: nil)
    }

    fileprivate func setNeedsDisplay() {
        self.setNeedsDisplay(.infinite)
    }



    // MARK: - Mouse Events

    fileprivate enum State {
        case idle
        case dragging(Int, CGPoint)
    }

    fileprivate var state: State = .idle {
        didSet { self.setNeedsDisplay() }
    }

    fileprivate var currentMouseLocation: CGPoint? = nil {
        didSet { self.updateHoveredPointIndexIfNeeded() }
    }

    fileprivate var hoveredPointIndex: Int? = nil {
        didSet { self.setNeedsDisplay() }
    }

    fileprivate func updateHoveredPointIndexIfNeeded() {
        let index = self.currentMouseLocation.flatMap({ self.indexOfPoint(at: $0) })

        if self.hoveredPointIndex != index {
            self.hoveredPointIndex = index
        }
    }

    private var trackingArea: NSTrackingArea? = nil {
        willSet {
            if let oldValue = self.trackingArea, oldValue !== newValue {
                self.removeTrackingArea(oldValue)
            }
        }
        didSet {
            if let newValue = self.trackingArea, newValue !== oldValue {
                self.addTrackingArea(newValue)
            }
        }
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()

        let rect = self.bounds
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .mouseEnteredAndExited]

        self.trackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: nil)
    }

    public override func mouseEntered(with event: NSEvent) {
        self.currentMouseLocation = self.location(of: event)
    }

    public override func mouseMoved(with event: NSEvent) {
        self.currentMouseLocation = self.location(of: event)
    }

    public override func mouseExited(with event: NSEvent) {
        self.currentMouseLocation = nil
    }

    public override func mouseDown(with event: NSEvent) {
        let location = self.location(of: event)

        if let index = self.indexOfPoint(at: location) {
            self.state = .dragging(index, location)
            self.currentMouseLocation = location
        }
        else {
            self.state = .idle
            self.currentMouseLocation = location
        }
    }

    public override func mouseDragged(with event: NSEvent) {
        guard case .dragging(let index, let reference) = self.state else { return }

        let location = self.location(of: event)

        let originalPoint = self.committedPath!.points[index]
        let originalLocation = originalPoint.applying(self.effectiveTransform)

        var modifiedLocation = originalLocation + (location - reference)
        modifiedLocation.x = fmin(fmax(modifiedLocation.x, self.bounds.minX), self.bounds.maxX)
        modifiedLocation.y = fmin(fmax(modifiedLocation.y, self.bounds.minY), self.bounds.maxY)

        let modifiedPoint = modifiedLocation.applying(self.effectiveTransform.inverted())
        let offset = modifiedPoint - originalPoint

        self.currentPath = self.committedPath!.displacingPoint(at: index, by: offset)
        self.currentMouseLocation = location
    }

    public override func mouseUp(with event: NSEvent) {
        if case .dragging = self.state {
            self.committedPath = self.currentPath!
        }

        self.state = .idle
        self.currentMouseLocation = self.location(of: event)
    }

    private func location(of event: NSEvent) -> CGPoint {
        return self.convert(event.locationInWindow, from: nil)
    }

    private func indexOfPoint(at location: CGPoint) -> Int? {
        guard let path = self.committedPath else { return nil }

        let locations = path.applying(self.effectiveTransform).points
        let distances = locations.map({ $0.distance(to: location) })

        if let minimum = distances.enumerated().min(by: { $0.element < $1.element }) {
            if minimum.element <= 20 {
                return minimum.offset
            }
        }

        return nil
    }
}
