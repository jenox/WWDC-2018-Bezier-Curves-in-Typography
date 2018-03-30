import CoreGraphics

extension CGPath {
    public static func roundedRect(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> CGPath {
        return CGPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    }

    public static func ellipse(width: CGFloat, height: CGFloat) -> CGPath {
        return CGPath(ellipseIn: CGRect(x: 0, y: 0, width: width, height: height), transform: nil)
    }
}
