import Cocoa


extension CGPath {

    /// Returns the outline of the given character when rendered using the given
    /// font.
    public static func outline(of character: Character, font: NSFont) -> CGPath {
        let string = NSAttributedString(string: String(character), attributes: [
            .font: font
        ])

        let line = CTLineCreateWithAttributedString(string)
        let path = CGMutablePath()

        for run in line.runs {
            let attributes = CTRunGetAttributes(run) as! [String: Any]
            let font = attributes[kCTFontAttributeName as String] as! CTFont

            for (glyph, position) in zip(run.glyphs, run.positions) {
                if let subpath = CTFontCreatePathForGlyph(font, glyph, nil) {
                    let transform = CGAffineTransform(translationX: position.x, y: position.y)

                    path.addPath(subpath, transform: transform)
                }
            }
        }

        return path
    }
}

extension CTLine {
    fileprivate var runs: [CTRun] {
        return CTLineGetGlyphRuns(self) as! [CTRun]
    }
}

extension CTRun {
    fileprivate var glyphs: [CGGlyph] {
        let count = CTRunGetGlyphCount(self)
        var glyphs = Array(repeating: 0 as CGGlyph, count: count)

        CTRunGetGlyphs(self, CFRangeMake(0, 0), &glyphs)

        return glyphs
    }

    fileprivate var positions: [CGPoint] {
        let count = CTRunGetGlyphCount(self)
        var points = Array(repeating: CGPoint.zero, count: count)

        CTRunGetPositions(self, CFRangeMake(0, 0), &points)

        return points
    }
}
