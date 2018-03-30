import Cocoa


extension NSColor {

    /// A repeatable `width×height` striped pattern color.
    internal static func stripes(width: Int, height: Int, color: NSColor, alpha: CGFloat) -> NSColor {
        let image = NSImage(size: CGSize(width: width, height: height))
        image.lockFocus()

        let context = NSGraphicsContext.current!.cgContext

        let dx = image.size.width
        let dy = image.size.height
        let thickness = dx * dy / 2 / hypot(dx, dy)

        context.beginPath()
        context.move(to: CGPoint(x: -1 * dx, y: -2 * dy))
        context.addLine(to: CGPoint(x: 2 * dx, y: 1 * dy))
        context.move(to: CGPoint(x: -1 * dx, y: -1 * dy))
        context.addLine(to: CGPoint(x: 2 * dx, y: 2 * dy))
        context.move(to: CGPoint(x: -1 * dx, y: 0 * dy))
        context.addLine(to: CGPoint(x: 2 * dx, y: 3 * dy))
        context.setLineWidth(thickness)
        context.setStrokeColor(color.cgColor)
        context.setAlpha(alpha)
        context.strokePath()

        image.unlockFocus()

        return NSColor(patternImage: image)
    }
}
