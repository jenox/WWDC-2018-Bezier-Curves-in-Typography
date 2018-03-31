import Foundation


extension CGPath {

    /// Does not currently support elements other than `<path>`. The `transform`
    /// attribute currently has no effect.
    public static func svg(named name: String) -> CGPath? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg") else {
            print("Error reading SVG: file not found")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            print("Error reading SVG: file could not be opened")
            return nil
        }

        guard let path = SimpleSVGParser(data: data)?.path else {
            print("Error reading SVG: file could not be parsed")
            return nil
        }

        return path
    }
}



fileprivate class SimpleSVGParser: NSObject, XMLParserDelegate {
    public init?(data: Data) {
        super.init()

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if parser.parserError != nil {
            return nil
        }
    }

    public let path: CGMutablePath = CGMutablePath()

    public func parser(_ parser: XMLParser, didStartElement tag: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if tag == "path" {
            guard let d = attributes["d"] else {
                return parser.abortParsing()
            }

            guard let path = CGPath.fromD(d) else {
                return parser.abortParsing()
            }

            self.path.addPath(path, transform: CGAffineTransform(scaleX: +1, y: -1))
        }
    }
}


extension Scanner {
    fileprivate enum ScanningError: Error {
        case typeMismatch(Any.Type)
    }

    fileprivate var currentCharacter: Character {
        let index = String.Index(encodedOffset: self.scanLocation)
        let character = self.string[index]

        return character
    }

    fileprivate func advance() {
        let currentIndex = String.Index(encodedOffset: self.scanLocation)
        let nextIndex = self.string.index(after: currentIndex)

        self.scanLocation = nextIndex.encodedOffset
    }

    fileprivate func skipWhitespace() {
        while !self.isAtEnd && [" ", ","].contains(self.currentCharacter) {
            self.advance()
        }
    }

    fileprivate func scanFloat() throws -> CGFloat {
        var value = 0 as Double

        self.skipWhitespace()

        if self.scanDouble(&value) {
            self.skipWhitespace()

            return CGFloat(value)
        }
        else {
            throw ScanningError.typeMismatch(CGFloat.self)
        }
    }

    fileprivate func scanPoint() throws -> CGPoint {
        let x = try self.scanFloat()
        let y = try self.scanFloat()

        return CGPoint(x: x, y: y)
    }

    fileprivate func scanVector() throws -> CGVector {
        let dx = try self.scanFloat()
        let dy = try self.scanFloat()

        return CGVector(dx: dx, dy: dy)
    }
}



extension CGPath {
    fileprivate enum ParsingError: Error {
        case unsupportedCommand
    }

    fileprivate static func fromD(_ d: String) -> CGPath? {
        let scanner = Scanner(string: d)
        let path = CGMutablePath()

        var lastCommand: Character? = nil
        var lastControlPoint: CGPoint? = nil

        func nextControlPointForSmoothCurve() -> CGPoint {
            return path.currentPoint + (path.currentPoint - (lastControlPoint ?? path.currentPoint))
        }

        do {
            while !scanner.isAtEnd {
                scanner.skipWhitespace()

                var command = scanner.currentCharacter

                if "01234567890 -+".contains(command) {
                    command = lastCommand!
                }
                else {
                    scanner.advance()
                }

                switch command {
                case "M":
                    let p = try scanner.scanPoint()

                    lastControlPoint = nil
                    path.move(to: p)
                case "m":
                    let dp = try scanner.scanVector()

                    lastControlPoint = nil
                    path.move(to: path.currentPoint + dp)
                case "L":
                    let p = try scanner.scanPoint()

                    lastControlPoint = nil
                    path.addLine(to: p)
                case "l":
                    let dp = try scanner.scanVector()

                    lastControlPoint = nil
                    path.addLine(to: path.currentPoint + dp)
                case "Q":
                    let c = try scanner.scanPoint()
                    let p = try scanner.scanPoint()

                    lastControlPoint = c
                    path.addQuadCurve(to: p, control: c)
                case "q":
                    let dc = try scanner.scanVector()
                    let dp = try scanner.scanVector()

                    lastControlPoint = path.currentPoint + dc
                    path.addQuadCurve(to: path.currentPoint + dp, control: path.currentPoint + dc)
                case "C":
                    let c1 = try scanner.scanPoint()
                    let c2 = try scanner.scanPoint()
                    let p = try scanner.scanPoint()

                    lastControlPoint = c2
                    path.addCurve(to: p, control1: c1, control2: c2)
                case "c":
                    let dc1 = try scanner.scanVector()
                    let dc2 = try scanner.scanVector()
                    let dp = try scanner.scanVector()

                    lastControlPoint = path.currentPoint + dc2
                    path.addCurve(to: path.currentPoint + dp, control1: path.currentPoint + dc1, control2: path.currentPoint + dc2)
                case "T":
                    let c = nextControlPointForSmoothCurve()
                    let p = try scanner.scanPoint()

                    lastControlPoint = c
                    path.addQuadCurve(to: p, control: c)
                case "t":
                    let c = nextControlPointForSmoothCurve()
                    let dp = try scanner.scanVector()

                    lastControlPoint = c
                    path.addQuadCurve(to: path.currentPoint + dp, control: c)
                case "S":
                    let c1 = nextControlPointForSmoothCurve()
                    let c2 = try scanner.scanPoint()
                    let p = try scanner.scanPoint()

                    lastControlPoint = c2
                    path.addCurve(to: p, control1: c1, control2: c2)
                case "s":
                    let c1 = nextControlPointForSmoothCurve()
                    let dc2 = try scanner.scanVector()
                    let dp = try scanner.scanVector()

                    lastControlPoint = path.currentPoint + dc2
                    path.addCurve(to: path.currentPoint + dp, control1: c1, control2: path.currentPoint + dc2)
                case "H":
                    let x = try scanner.scanFloat()

                    lastControlPoint = nil
                    path.addLine(to: CGPoint(x: x, y: path.currentPoint.y))
                case "h":
                    let dx = try scanner.scanFloat()

                    lastControlPoint = nil
                    path.addLine(to: CGPoint(x: path.currentPoint.x + dx, y: path.currentPoint.y))
                case "V":
                    let y = try scanner.scanFloat()

                    lastControlPoint = nil
                    path.addLine(to: CGPoint(x: path.currentPoint.x, y: y))
                case "v":
                    let dy = try scanner.scanFloat()

                    lastControlPoint = nil
                    path.addLine(to: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y + dy))
                case "Z":
                    lastControlPoint = nil
                    path.closeSubpath()
                case "z":
                    lastControlPoint = nil
                    path.closeSubpath()
                default:
                    throw ParsingError.unsupportedCommand
                }

                lastCommand = command
            }
        }
        catch let error {
            print("Error parsing svg path:", error)
            return nil
        }

        return path
    }

    fileprivate func toD() -> String {
        var string = ""

        self.applyWithBlock({ pointer in
            let element = pointer.pointee

            if !string.isEmpty {
                string.append(" ")
            }

            switch element.type {
            case .moveToPoint:
                let p = element.points[0]
                string.append("M \(p.x),\(p.y)")
            case .addLineToPoint:
                let p = element.points[0]
                string.append("L \(p.x),\(p.y)")
            case .addQuadCurveToPoint:
                let p = element.points[1]
                let c = element.points[0]
                string.append("Q \(c.x),\(c.y) \(p.x),\(p.y)")
            case .addCurveToPoint:
                let p = element.points[2]
                let c1 = element.points[0]
                let c2 = element.points[1]
                string.append("C \(c1.x),\(c1.y) \(c2.x),\(c2.y) \(p.x),\(p.y)")
            case .closeSubpath:
                string.append("Z")
            }
        })

        return string
    }
}
