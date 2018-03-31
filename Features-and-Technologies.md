> “Tell us about the features and technologies you used in your Swift playground.” ― Apple

---

Bézier curves are parametric curves between two endpoints that can be linked together to form smooth paths that can be scaled indefinitely without a loss of detail.

Although the idea of Bézier curves itself is a purely mathematical concept, we unknowingly consume them every day: Fonts define the outline of individual glyphs as a sequence of linked Bézier curves, allowing the glyphs to look smooth at all sizes. Vector graphics, such as SVG, also utilize Bézier curves to ensure they look great at all sizes. In contrast, when increasing the size of a rasterized image, one will quickly notice the loss of detail. When drawing content to the screen, everything needs to be rasterized eventually, but vector fonts and graphics perform this step at the very last, and not at the time they are designed.

This playground allows you to get a feel for how Bézier curves work and how complex glyphs or icons can be built by linking multiple curves together. You can load up any `CGPath` you want and move its end- and control points around to see how it affects the path.

---

Swift Extensions are used to add operators for common mathematical operations on fundamental Core Graphics types, allowing for more concise code when dealing with said types.

Disassembling the input Bézier path into its curves is done using Core Graphics APIs. Those are also responsible for drawing the curves and their control points to the screen. The sample paths in the playground come from two sources: the outlines of individual glyphs are retrieved using low-level Core Text APIs, while `NSXMLParser` and `NSScanner` are used to parse basic `.svg` input files.

In addition to just seeing how multiple Bézier curves can be linked together to form more complex shapes, the user can also interact with those curves and move their control points around. App Kit is responsible for delivering the mouse events here.
