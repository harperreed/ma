// ABOUTME: Utility for extracting dominant colors from album artwork
// ABOUTME: Provides color analysis for dynamic background generation

import Foundation
#if canImport(AppKit)
import AppKit
import SwiftUI

class ColorExtractor {
    /// Extract the dominant color from an image using histogram analysis
    func extractDominantColor(from image: NSImage) -> Color? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample pixels (every 10th pixel for performance)
        var redSum = 0
        var greenSum = 0
        var blueSum = 0
        var count = 0

        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = (y * width + x) * bytesPerPixel
                let red = Int(pixelData[offset])
                let green = Int(pixelData[offset + 1])
                let blue = Int(pixelData[offset + 2])

                redSum += red
                greenSum += green
                blueSum += blue
                count += 1
            }
        }

        guard count > 0 else { return nil }

        let avgRed = Double(redSum) / Double(count) / 255.0
        let avgGreen = Double(greenSum) / Double(count) / 255.0
        let avgBlue = Double(blueSum) / Double(count) / 255.0

        return Color(red: avgRed, green: avgGreen, blue: avgBlue)
    }

    /// Extract a color palette from an image
    func extractPalette(from image: NSImage, count: Int) -> [Color] {
        // For now, return variations of the dominant color
        guard let dominant = extractDominantColor(from: image) else {
            return []
        }

        var palette: [Color] = [dominant]

        // Add lighter and darker variations
        if count > 1 {
            palette.append(dominant.opacity(0.7))
        }
        if count > 2 {
            palette.append(dominant.opacity(0.4))
        }

        return palette
    }
}
#endif
