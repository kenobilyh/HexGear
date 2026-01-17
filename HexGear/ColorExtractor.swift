//
//  ColorExtractor.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/17.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Color Extractor Logic
class ColorExtractor {
    
    // 1. CIAreaAverage
    static func extractAreaAverage(from image: NSImage) -> Color? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return nil }
        
        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.extent = ciImage.extent
        
        guard let outputImage = filter.outputImage else { return nil }
        return renderOnePixelColor(from: outputImage)
    }
    
    // 2. Scale to 1x1
    static func extractScaled1x1(from image: NSImage) -> Color? {
        // Create a 1x1 bitmap context
        let width = 1
        let height = 1
        let bitsPerComponent = 8
        let bytesPerRow = 4 * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        // Draw image into 1x1 context (this effectively averages the pixels)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        guard let data = context.data else { return nil }
        
        let pointer = data.bindMemory(to: UInt8.self, capacity: 4)
        let r = Double(pointer[0]) / 255.0
        let g = Double(pointer[1]) / 255.0
        let b = Double(pointer[2]) / 255.0
        let a = Double(pointer[3]) / 255.0
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    // 3. CIAreaHistogram -> Dominant Color
    static func extractHistogramDominant(from image: NSImage) -> Color? {
        // Logic: Create a histogram (e.g. 64 bins), find the bin with max value
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return nil }
        
        // We will use 8x8x8 = 512 total bins for crude dominant color
        let count = 8
        let scale = 255.0 / Float(count)
        
        let filter = CIFilter.areaHistogram()
        filter.inputImage = ciImage
        filter.extent = ciImage.extent
        filter.count = count // Bins per channel
        filter.scale = scale
        
        guard let histogramImage = filter.outputImage else { return nil }
        
        let context = CIContext()
        
        guard let cgOutput = context.createCGImage(histogramImage, from: histogramImage.extent) else { return nil }
        
        let width = cgOutput.width // should be count * 4 (RGBA)
        let height = cgOutput.height // 1
        
        // Read data
        // We render execution to a bitmap to read float values.
        // Let's use a local buffer.
        
        var bitmap = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: &bitmap, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        ctx?.draw(cgOutput, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Reading raw float buffer approach preferred for accuracy but using available drawn bitmap for now
        // as per previous implementation logic copy.
        
        let outputExtent = histogramImage.extent
        let rawData = UnsafeMutablePointer<Float>.allocate(capacity: Int(outputExtent.width * outputExtent.height * 4))
        defer { rawData.deallocate() }
        
        context.render(histogramImage, 
                       toBitmap: rawData, 
                       rowBytes: Int(Int(outputExtent.width) * 4 * MemoryLayout<Float>.size), 
                       bounds: outputExtent, 
                       format: .RGBAf, 
                       colorSpace: nil)

        let bins = count
        
        var maxR = 0
        var maxRIndex = 0
        var maxG = 0
        var maxGIndex = 0
        var maxB = 0
        var maxBIndex = 0
        
        for i in 0..<bins {
            // Read float value
            let rVal = rawData[i] // Red bin i
            if rVal > Float(maxR) { maxR = Int(rVal); maxRIndex = i }
            
            let gVal = rawData[i + bins] // Green bin i
            if gVal > Float(maxG) { maxG = Int(gVal); maxGIndex = i }
            
            let bVal = rawData[i + bins * 2] // Blue bin i
            if bVal > Float(maxB) { maxB = Int(bVal); maxBIndex = i }
        }
        
        // Convert index to color component (center of bin)
        let binSize = 1.0 / Double(bins)
        let r = (Double(maxRIndex) * binSize) + (binSize / 2)
        let g = (Double(maxGIndex) * binSize) + (binSize / 2)
        let b = (Double(maxBIndex) * binSize) + (binSize / 2)
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
    
    // Helper to read 1 pixel
    private static func renderOnePixelColor(from image: CIImage) -> Color? {
        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(image, 
                       toBitmap: &bitmap, 
                       rowBytes: 4, 
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
                       format: .RGBA8, 
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0
        let a = Double(bitmap[3]) / 255.0
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
