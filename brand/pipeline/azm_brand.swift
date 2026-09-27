// Azm brand pipeline: renders every icon / splash asset from ONE SVG.
// Run it through `brand/generate.sh` (compiles this file, handles --check).
//
//   azm_brand <source.svg> <theme.json> <out-root>
//
// <out-root> mirrors the repo root: files land in <out-root>/app/android/…,
// <out-root>/app/ios/…, <out-root>/brand/exports/…. Output is deterministic,
// so a second run over the same inputs produces byte-identical files.
//
// Source contract (brand/README.md): a square viewBox whose FIRST element is a
// <rect> "plate" covering it; everything after the plate is "the mark". Only
// macOS frameworks are used (AppKit renders the SVG, ImageIO writes PNGs).

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Errors, small helpers

struct BrandError: Error, CustomStringConvertible {
  let description: String
  init(_ d: String) { description = d }
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(("azm_brand: " + message + "\n").data(using: .utf8)!)
  exit(1)
}

func firstMatch(_ pattern: String, in s: String, options: NSRegularExpression.Options = []) -> NSTextCheckingResult? {
  let re = try! NSRegularExpression(pattern: pattern, options: options)
  return re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
}

func group(_ m: NSTextCheckingResult, _ i: Int, in s: String) -> String? {
  guard let r = Range(m.range(at: i), in: s) else { return nil }
  return String(s[r])
}

struct RGB: Equatable {
  var r: Double, g: Double, b: Double  // 0…1
  init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
  init(hex: String) throws {
    var h = hex.trimmingCharacters(in: .whitespaces)
    if h.hasPrefix("#") { h.removeFirst() }
    if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
    guard h.count == 6 || h.count == 8, let v = UInt32(h.prefix(6), radix: 16) else { throw BrandError("bad colour \(hex)") }
    r = Double((v >> 16) & 0xFF) / 255; g = Double((v >> 8) & 0xFF) / 255; b = Double(v & 0xFF) / 255
  }
  var hex: String {
    String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
  }
  func distance(to o: RGB) -> Double { sqrt(pow(r - o.r, 2) + pow(g - o.g, 2) + pow(b - o.b, 2)) / sqrt(3) }
}

// MARK: - Source SVG and its derived variants

struct Source {
  let text: String
  let plateTag: String  // the full <rect …/> plate element
  let plateColor: RGB
  let colors: [String]  // every #hex colour the SVG uses (upper-cased)

  init(path: String) throws {
    text = try String(contentsOfFile: path, encoding: .utf8)
    guard let vb = firstMatch(#"viewBox\s*=\s*"\s*([-\d.]+)[\s,]+([-\d.]+)[\s,]+([-\d.]+)[\s,]+([-\d.]+)\s*""#, in: text),
      let w = Double(group(vb, 3, in: text)!), let h = Double(group(vb, 4, in: text)!), w == h
    else { throw BrandError("the SVG needs a square viewBox") }
    // First element after <svg …>: must be the plate <rect>.
    guard let m = firstMatch(#"<svg\b[^>]*>\s*(?:<!--.*?-->\s*)*(<rect\b[^>]*?/>)"#, in: text, options: [.dotMatchesLineSeparators]),
      let tag = group(m, 1, in: text)
    else { throw BrandError("the first element inside <svg> must be the plate: a self-closing <rect …/>") }
    plateTag = tag
    for (attr, want) in [("width", w), ("height", h)] {
      guard let a = firstMatch("\\b\(attr)\\s*=\\s*\"([\\d.]+)\"", in: tag), Double(group(a, 1, in: tag)!) == want else {
        throw BrandError("the plate <rect> must cover the whole viewBox (\(attr)=\"\(Int(want))\")")
      }
    }
    guard let f = firstMatch(#"\bfill\s*=\s*"(#[0-9A-Fa-f]{3,8})""#, in: tag) else {
      throw BrandError("the plate <rect> needs a fill=\"#RRGGBB\"")
    }
    plateColor = try RGB(hex: group(f, 1, in: tag)!)
    let re = try! NSRegularExpression(pattern: "#[0-9A-Fa-f]{6}\\b|#[0-9A-Fa-f]{3}\\b")
    let t = text
    colors = Array(Set(re.matches(in: t, range: NSRange(t.startIndex..., in: t)).map {
      try! RGB(hex: String(t[Range($0.range, in: t)!])).hex
    })).sorted()
  }

  /// The source as-is: rounded plate, transparent corners.
  var full: String { text }
  /// Plate without corner radius: full-bleed square (iOS light, Play Store).
  var square: String {
    var t = plateTag
    for a in ["rx", "ry"] {
      t = t.replacingOccurrences(of: "\\s\(a)\\s*=\\s*\"[^\"]*\"", with: "", options: .regularExpression)
    }
    return text.replacingOccurrences(of: plateTag, with: t)
  }
  /// Everything but the plate, on transparent.
  var mark: String { text.replacingOccurrences(of: plateTag, with: "") }
}

// MARK: - Rendering

typealias Bitmap = (data: [UInt8], w: Int, h: Int)  // RGBA8, premultiplied

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func makeImage(_ svg: String) throws -> NSImage {
  guard let img = NSImage(data: svg.data(using: .utf8)!), img.isValid else { throw BrandError("AppKit could not render the SVG") }
  return img
}

/// Draws [svg] into a [w]×[h] px canvas, its (square) viewBox filling [rect]
/// (px, origin top-left). Optional opaque [background] under it.
func render(_ svg: String, w: Int, h: Int, rect: CGRect, background: RGB? = nil) throws -> Bitmap {
  let img = try makeImage(svg)
  var buf = [UInt8](repeating: 0, count: w * h * 4)
  try buf.withUnsafeMutableBytes { raw in
    guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
      space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw BrandError("CGContext") }
    if let bg = background {
      ctx.setFillColor(CGColor(colorSpace: srgb, components: [bg.r, bg.g, bg.b, 1])!)
      ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    }
    ctx.interpolationQuality = .high
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns
    // CG origin is bottom-left; callers think top-left.
    let r = CGRect(x: rect.minX, y: CGFloat(h) - rect.maxY, width: rect.width, height: rect.height)
    img.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
  }
  return (buf, w, h)
}

/// Monochrome: every painted pixel becomes white; pixels painted in the plate
/// colour (holes such as the barbell sleeve) become transparent. Alpha only
/// is what Android's themed icons / notification icons use.
func monochrome(_ b: Bitmap, cutting plate: RGB) -> Bitmap {
  var out = b.data
  for i in stride(from: 0, to: out.count, by: 4) {
    let a = Double(out[i + 3]) / 255
    guard a > 0 else { continue }
    let c = RGB(r: Double(out[i]) / 255 / a, g: Double(out[i + 1]) / 255 / a, b: Double(out[i + 2]) / 255 / a)
    let keep = min(1, c.distance(to: plate) / 0.25)
    let na = UInt8((a * keep * 255).rounded())
    out[i] = na; out[i + 1] = na; out[i + 2] = na; out[i + 3] = na  // white, premultiplied
  }
  return (out, b.w, b.h)
}

/// Luminance grayscale (iOS tinted appearance). Input must be opaque.
func grayscale(_ b: Bitmap) -> Bitmap {
  var out = b.data
  for i in stride(from: 0, to: out.count, by: 4) {
    let y = 0.2126 * Double(out[i]) + 0.7152 * Double(out[i + 1]) + 0.0722 * Double(out[i + 2])
    let v = UInt8(min(255, y.rounded()))
    out[i] = v; out[i + 1] = v; out[i + 2] = v
  }
  return (out, b.w, b.h)
}

/// Farthest painted pixel from the canvas centre, as a fraction of the edge,
/// and the painted bounding box (fractions of the edge).
func extent(_ b: Bitmap) -> (radius: Double, box: CGRect) {
  var r2 = 0.0, minX = b.w, minY = b.h, maxX = -1, maxY = -1
  let cx = Double(b.w) / 2, cy = Double(b.h) / 2
  for y in 0..<b.h {
    for x in 0..<b.w where b.data[(y * b.w + x) * 4 + 3] > 8 {
      let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
      r2 = max(r2, dx * dx + dy * dy)
      minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    }
  }
  guard maxX >= 0 else { fail("the mark (everything after the plate) is empty") }
  let s = Double(b.w)
  return ((r2.squareRoot() + 1) / s,
    CGRect(x: Double(minX) / s, y: Double(minY) / s, width: Double(maxX - minX + 1) / s, height: Double(maxY - minY + 1) / s))
}

func cgImage(_ b: Bitmap) -> CGImage {
  let provider = CGDataProvider(data: Data(b.data) as CFData)!
  return CGImage(width: b.w, height: b.h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: b.w * 4, space: srgb,
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil,
    shouldInterpolate: false, intent: .defaultIntent)!
}

func writePNG(_ b: Bitmap, to path: String) throws {
  try FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
  let cg = cgImage(b)
  guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)
  else { throw BrandError("PNG \(path)") }
  CGImageDestinationAddImage(dest, cg, nil)
  guard CGImageDestinationFinalize(dest) else { throw BrandError("PNG write \(path)") }
}

/// Opaque copy (alpha forced to 255, colour un-premultiplied over [bg]).
func flatten(_ b: Bitmap, over bg: RGB) -> Bitmap {
  var out = b.data
  for i in stride(from: 0, to: out.count, by: 4) {
    let a = Double(out[i + 3]) / 255
    out[i] = UInt8((Double(out[i]) + bg.r * 255 * (1 - a)).rounded())
    out[i + 1] = UInt8((Double(out[i + 1]) + bg.g * 255 * (1 - a)).rounded())
    out[i + 2] = UInt8((Double(out[i + 2]) + bg.b * 255 * (1 - a)).rounded())
    out[i + 3] = 255
  }
  return (out, b.w, b.h)
}

func write(_ text: String, to path: String) throws {
  try FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
  try text.write(toFile: path, atomically: true, encoding: .utf8)
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count == 4 else { fail("usage: azm_brand <source.svg> <theme.json> <out-root>") }
let (svgPath, themePath, outRoot) = (args[1], args[2], args[3])

do {
  let src = try Source(path: svgPath)

  // Colours: the SVG may only use design-system colours; splash = dark page background.
  let theme = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: themePath))) as! [String: Any]
  let colors = (theme["colors"] as? [String: Any] ?? [:]).compactMapValues { ($0 as? [String: Any])?.compactMapValues { $0 as? String } }
  let palette = Set(colors.values.flatMap { $0.values }.filter { $0.hasPrefix("#") && $0.count == 7 }.map { $0.uppercased() })
  let foreign = src.colors.filter { !palette.contains($0) }
  guard foreign.isEmpty else {
    throw BrandError("colours not in design/theme.json: \(foreign.joined(separator: ", ")) (no new colours, docs/DESIGN.md)")
  }
  guard let pageDark = colors["dark"]?["pageBackground"] else { throw BrandError("theme.json: colors.dark.pageBackground missing") }
  let splashBg = try RGB(hex: pageDark)
  let plate = src.plateColor

  let res = "\(outRoot)/app/android/app/src/main/res"
  let ios = "\(outRoot)/app/ios/Runner"
  let exports = "\(outRoot)/brand/exports"

  // Geometry of the mark, measured once at 1024 px in viewBox space.
  let probe = extent(try render(src.mark, w: 1024, h: 1024, rect: CGRect(x: 0, y: 0, width: 1024, height: 1024)))
  let monoProbe = extent(monochrome(try render(src.mark, w: 1024, h: 1024, rect: CGRect(x: 0, y: 0, width: 1024, height: 1024)), cutting: plate))

  /// The mark centred on the canvas centre, scaled so its farthest pixel sits
  /// on a circle of [radius] px (Android adaptive safe zone, splash circle).
  func markInCircle(canvas: Int, radius: Double) -> CGRect {
    let side = radius / probe.radius
    let o = (Double(canvas) - side) / 2
    return CGRect(x: o, y: o, width: side, height: side)
  }

  let densities: [(String, Double)] = [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3), ("xxxhdpi", 4)]
  for (d, s) in densities {
    // Legacy launcher (API < 26): the rounded plate, 48 dp with a 2 dp margin.
    let l = Int(48 * s), m = 2 * s
    try writePNG(try render(src.full, w: l, h: l, rect: CGRect(x: m, y: m, width: Double(l) - 2 * m, height: Double(l) - 2 * m)),
      to: "\(res)/mipmap-\(d)/ic_launcher.png")
    // Adaptive layers: 108 dp canvas, mark inside the 66 dp safe-zone circle.
    let a = Int(108 * s)
    let fg = try render(src.mark, w: a, h: a, rect: markInCircle(canvas: a, radius: 33 * s))
    try writePNG(fg, to: "\(res)/mipmap-\(d)/ic_launcher_foreground.png")
    try writePNG(monochrome(fg, cutting: plate), to: "\(res)/mipmap-\(d)/ic_launcher_monochrome.png")
    // Notification (status bar): 24 dp, monochrome, fitted into 22 dp.
    let n = Int(24 * s)
    let box = monoProbe.box
    let side = 22 * s / max(box.width, box.height)
    let nr = CGRect(x: (Double(n) - side * box.width) / 2 - side * box.minX, y: (Double(n) - side * box.height) / 2 - side * box.minY,
      width: side, height: side)
    try writePNG(monochrome(try render(src.mark, w: n, h: n, rect: nr), cutting: plate), to: "\(res)/drawable-\(d)/ic_stat_azm.png")
    // Splash icon: Android 12 spec, 288 dp canvas, mark within the 192 dp circle.
    let sp = Int(288 * s)
    try writePNG(try render(src.mark, w: sp, h: sp, rect: markInCircle(canvas: sp, radius: 96 * s)), to: "\(res)/drawable-\(d)/splash_icon.png")
  }

  let header = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!-- GENERATED by brand/generate.sh from brand/logo-concept-a.svg. Do not edit. -->\n"
  try write(header + """
    <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
        <background android:drawable="@color/azm_icon_background" />
        <foreground android:drawable="@mipmap/ic_launcher_foreground" />
        <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
    </adaptive-icon>

    """, to: "\(res)/mipmap-anydpi-v26/ic_launcher.xml")
  try write(header + """
    <resources>
        <!-- Icon plate (the SVG's plate fill) and splash = dark pageBackground (design/theme.json). -->
        <color name="azm_icon_background">\(plate.hex)</color>
        <color name="azm_splash_background">\(splashBg.hex)</color>
    </resources>

    """, to: "\(res)/values/colors.xml")
  let launch = header + """
    <!-- Pre-Android-12 launch window: dark background + the mark, centred. -->
    <layer-list xmlns:android="http://schemas.android.com/apk/res/android">
        <item android:drawable="@color/azm_splash_background" />
        <item>
            <bitmap android:gravity="center" android:src="@drawable/splash_icon" />
        </item>
    </layer-list>

    """
  try write(launch, to: "\(res)/drawable/launch_background.xml")
  try write(launch, to: "\(res)/drawable-v21/launch_background.xml")
  // Splash is dark whatever the system theme (dark is the app default).
  let styles = header + """
    <resources>
        <!-- Launch window until Flutter draws its first frame. -->
        <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
            <item name="android:windowBackground">@drawable/launch_background</item>
        </style>
        <!-- Window behind the Flutter UI (io.flutter.embedding.android.NormalTheme). -->
        <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
            <item name="android:windowBackground">@color/azm_splash_background</item>
        </style>
    </resources>

    """
  try write(styles, to: "\(res)/values/styles.xml")
  try write(styles, to: "\(res)/values-night/styles.xml")
  let styles31 = header + """
    <resources>
        <!-- Android 12+ splash screen API: dark background + the mark. -->
        <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
            <item name="android:windowBackground">@drawable/launch_background</item>
            <item name="android:windowSplashScreenBackground">@color/azm_splash_background</item>
            <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
        </style>
        <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
            <item name="android:windowBackground">@color/azm_splash_background</item>
        </style>
    </resources>

    """
  try write(styles31, to: "\(res)/values-v31/styles.xml")
  try write(styles31, to: "\(res)/values-night-v31/styles.xml")

  // iOS AppIcon: single 1024 size, light / dark / tinted appearances.
  let full1024 = CGRect(x: 0, y: 0, width: 1024, height: 1024)
  let light = flatten(try render(src.square, w: 1024, h: 1024, rect: full1024), over: plate)  // no transparency
  let icons = "\(ios)/Assets.xcassets/AppIcon.appiconset"
  try writePNG(light, to: "\(icons)/AppIcon-light.png")
  try writePNG(try render(src.mark, w: 1024, h: 1024, rect: full1024), to: "\(icons)/AppIcon-dark.png")
  try writePNG(grayscale(light), to: "\(icons)/AppIcon-tinted.png")
  try write("""
    {
      "images" : [
        {
          "filename" : "AppIcon-light.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "filename" : "AppIcon-dark.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "tinted"
            }
          ],
          "filename" : "AppIcon-tinted.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "azm-brand",
        "version" : 1
      }
    }

    """, to: "\(icons)/Contents.json")

  // iOS launch screen: 288 pt image (same geometry as the Android splash icon).
  let launchSet = "\(ios)/Assets.xcassets/LaunchImage.imageset"
  for (suffix, s) in [("", 1.0), ("@2x", 2.0), ("@3x", 3.0)] {
    let sp = Int(288 * s)
    try writePNG(try render(src.mark, w: sp, h: sp, rect: markInCircle(canvas: sp, radius: 96 * s)), to: "\(launchSet)/LaunchImage\(suffix).png")
  }
  try write("""
    {
      "images" : [
        {
          "filename" : "LaunchImage.png",
          "idiom" : "universal",
          "scale" : "1x"
        },
        {
          "filename" : "LaunchImage@2x.png",
          "idiom" : "universal",
          "scale" : "2x"
        },
        {
          "filename" : "LaunchImage@3x.png",
          "idiom" : "universal",
          "scale" : "3x"
        }
      ],
      "info" : {
        "author" : "azm-brand",
        "version" : 1
      }
    }

    """, to: "\(launchSet)/Contents.json")
  func comp(_ v: Double) -> String { String(format: "%.6f", v) }
  try write("""
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <!-- GENERATED by brand/generate.sh from brand/logo-concept-a.svg. Do not edit. -->
    <document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="12121" systemVersion="16G29" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
        <dependencies>
            <deployment identifier="iOS"/>
            <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="12089"/>
        </dependencies>
        <scenes>
            <!--View Controller-->
            <scene sceneID="EHf-IW-A2E">
                <objects>
                    <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                        <layoutGuides>
                            <viewControllerLayoutGuide type="top" id="Ydg-fD-yQy"/>
                            <viewControllerLayoutGuide type="bottom" id="xbc-2k-c8Z"/>
                        </layoutGuides>
                        <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                            <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                            <subviews>
                                <imageView opaque="NO" clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="center" image="LaunchImage" translatesAutoresizingMaskIntoConstraints="NO" id="YRO-k0-Ey4">
                                </imageView>
                            </subviews>
                            <color key="backgroundColor" red="\(comp(splashBg.r))" green="\(comp(splashBg.g))" blue="\(comp(splashBg.b))" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                            <constraints>
                                <constraint firstItem="YRO-k0-Ey4" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="1a2-6s-vTC"/>
                                <constraint firstItem="YRO-k0-Ey4" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="4X2-HB-R7a"/>
                            </constraints>
                        </view>
                    </viewController>
                    <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
                </objects>
                <point key="canvasLocation" x="53" y="375"/>
            </scene>
        </scenes>
        <resources>
            <image name="LaunchImage" width="288" height="288"/>
        </resources>
    </document>

    """, to: "\(ios)/Base.lproj/LaunchScreen.storyboard")

  // Store + review exports.
  try writePNG(flatten(try render(src.square, w: 512, h: 512, rect: CGRect(x: 0, y: 0, width: 512, height: 512)), over: plate),
    to: "\(exports)/play_store_512.png")
  // Small-size legibility sheet: the launcher icon at 16…64 px drawn at its
  // real pixel size, then the 48 px icon magnified 4× (nearest neighbour) so
  // a reviewer sees the actual pixels. Row 1 on the light page background,
  // row 2 on the dark one (design/theme.json).
  let pageLight = try RGB(hex: colors["light"]?["pageBackground"] ?? "#FFFFFF")
  let sizes = [16, 20, 29, 40, 48, 64]
  let gap = 16, zoom = 4, zoomed = 48 * zoom
  let rowH = zoomed + 2 * gap
  let sheetW = sizes.reduce(gap) { $0 + $1 + gap } + zoomed + gap
  let sheetH = 2 * rowH
  var sheet = [UInt8](repeating: 255, count: sheetW * sheetH * 4)
  func blend(_ icon: Bitmap, at x0: Int, _ y0: Int, scale: Int) {
    for yy in 0..<(icon.h * scale) {
      for xx in 0..<(icon.w * scale) {
        let si = ((yy / scale) * icon.w + xx / scale) * 4, di = ((y0 + yy) * sheetW + x0 + xx) * 4
        let a = Double(icon.data[si + 3]) / 255
        for c in 0..<3 { sheet[di + c] = UInt8((Double(icon.data[si + c]) + Double(sheet[di + c]) * (1 - a)).rounded()) }
      }
    }
  }
  for (row, bg) in [pageLight, splashBg].enumerated() {
    for y in (row * rowH)..<((row + 1) * rowH) {
      for x in 0..<sheetW {
        let i = (y * sheetW + x) * 4
        sheet[i] = UInt8((bg.r * 255).rounded()); sheet[i + 1] = UInt8((bg.g * 255).rounded()); sheet[i + 2] = UInt8((bg.b * 255).rounded())
      }
    }
    var x = gap
    let base = row * rowH + gap + zoomed  // icons sit on a common baseline
    for s in sizes {
      let icon = try render(src.full, w: s, h: s, rect: CGRect(x: 0, y: 0, width: s, height: s))
      blend(icon, at: x, base - s, scale: 1)
      if s == 48 { blend(icon, at: sheetW - gap - zoomed, row * rowH + gap, scale: zoom) }
      x += s + gap
    }
  }
  try writePNG((sheet, sheetW, sheetH), to: "\(exports)/legibility_16-64px.png")

  // Review sheet (not shipped): every variant as a launcher would show it,
  // on design-system backgrounds. 1 legacy · 2 adaptive (circle mask) ·
  // 3 Android 13 themed (monochrome) · 4 notification · 5–7 iOS light / dark /
  // tinted (rounded mask) · 8 splash.
  let fillDark = try RGB(hex: colors["dark"]?["fill"] ?? "#2A2A2E")
  let cardDark = try RGB(hex: colors["dark"]?["card"] ?? "#1C1C1E")
  let tile = 216, pad = 16
  let tiles = 8
  let rw = tiles * tile + (tiles + 1) * pad, rh = tile + 2 * pad
  var review = [UInt8](repeating: 0, count: rw * rh * 4)
  try review.withUnsafeMutableBytes { raw in
    guard let ctx = CGContext(data: raw.baseAddress, width: rw, height: rh, bitsPerComponent: 8, bytesPerRow: rw * 4,
      space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw BrandError("CGContext") }
    func color(_ c: RGB) -> CGColor { CGColor(colorSpace: srgb, components: [c.r, c.g, c.b, 1])! }
    ctx.setFillColor(color(cardDark))
    ctx.fill(CGRect(x: 0, y: 0, width: rw, height: rh))
    ctx.interpolationQuality = .high
    let t = Double(tile)
    func slot(_ i: Int) -> CGRect { CGRect(x: Double(pad + i * (tile + pad)), y: Double(pad), width: t, height: t) }
    func draw(_ b: Bitmap, _ r: CGRect, clip: CGPath? = nil, under: RGB? = nil) {
      ctx.saveGState()
      if let clip = clip { ctx.addPath(clip); ctx.clip() }
      if let u = under { ctx.setFillColor(color(u)); ctx.fill(r) }
      ctx.draw(cgImage(b), in: r)
      ctx.restoreGState()
    }
    // 1 legacy: xxxhdpi ic_launcher.
    draw(try render(src.full, w: tile, h: tile, rect: CGRect(x: 8, y: 8, width: t - 16, height: t - 16)), slot(0))
    // 2 + 3 adaptive: 108 dp layer, launcher shows the central 72 dp as a circle.
    let layer = Int(t * 108 / 72)
    let fg = try render(src.mark, w: layer, h: layer, rect: markInCircle(canvas: layer, radius: 33 * Double(layer) / 108))
    for (i, img, bg) in [(1, fg, plate), (2, monochrome(fg, cutting: plate), fillDark)] {
      let r = slot(i), l = Double(layer)
      draw(img, CGRect(x: r.midX - l / 2, y: r.midY - l / 2, width: l, height: l), clip: CGPath(ellipseIn: r, transform: nil), under: bg)
    }
    // 4 notification: 24 dp icon at xxxhdpi, magnified 2×.
    let n = Int(24 * 4.0), box = monoProbe.box, side = 22 * 4.0 / max(box.width, box.height)
    let nr = CGRect(x: (Double(n) - side * box.width) / 2 - side * box.minX, y: (Double(n) - side * box.height) / 2 - side * box.minY,
      width: side, height: side)
    let r3 = slot(3)
    ctx.setFillColor(color(fillDark)); ctx.fill(r3)
    draw(monochrome(try render(src.mark, w: n, h: n, rect: nr), cutting: plate), r3.insetBy(dx: (t - Double(2 * n)) / 2, dy: (t - Double(2 * n)) / 2))
    // 5–7 iOS appearances, masked like the home screen (continuous corners ~22.37%).
    let full = CGRect(x: 0, y: 0, width: tile, height: tile)
    let lightT = flatten(try render(src.square, w: tile, h: tile, rect: full), over: plate)
    for (i, img, under) in [(4, lightT, nil), (5, try render(src.mark, w: tile, h: tile, rect: full), splashBg), (6, grayscale(lightT), nil)] as [(Int, Bitmap, RGB?)] {
      let r = slot(i)
      draw(img, r, clip: CGPath(roundedRect: r, cornerWidth: t * 0.2237, cornerHeight: t * 0.2237, transform: nil), under: under)
    }
    // 8 splash icon on the splash background.
    let r7 = slot(7)
    ctx.setFillColor(color(splashBg)); ctx.fill(r7)
    draw(try render(src.mark, w: tile, h: tile, rect: markInCircle(canvas: tile, radius: 96 * t / 288)), r7)
  }
  try writePNG((review, rw, rh), to: "\(exports)/review_sheet.png")

  print("azm_brand: plate \(plate.hex), splash \(splashBg.hex), colours \(src.colors.joined(separator: " ")); "
    + "mark radius \(String(format: "%.3f", probe.radius)) of the edge")
} catch {
  fail("\(error)")
}
