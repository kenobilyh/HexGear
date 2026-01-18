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
    
    // 3. CPU 3D Histogram -> Dominant Color (True Mode)
    // Fixes the issue where CIAreaHistogram analyzes channels independently, potentially creating colors that don't exist.
    static func extractHistogramDominant(from image: NSImage) -> Color? {
        // Resize to a manageable size for CPU processing (e.g. 100x100)
        let sampleSize = CGSize(width: 50, height: 50)
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        let width = Int(sampleSize.width)
        let height = Int(sampleSize.height)
        let bitsPerComponent = 8
        let bytesPerRow = 4 * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Draw to bitmap
        // Using calloc-based memory via CGContext is easiest
        var bitmapData = [UInt8](repeating: 0, count: width * height * 4)
        
        guard let context = CGContext(data: &bitmapData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Build 3D Histogram (Frequency Map)
        // Quantize colors to reduce sparsity (e.g. reduce 256 -> 32 levels) includes significant noise reduction
        var frequency: [Int: Int] = [:]
        let quantizationShift = 3 // 2^3 = 8, so 256/8 = 32 levels per channel
        
        for i in 0..<(width * height) {
            let offset = i * 4
            let r = bitmapData[offset]
            let g = bitmapData[offset+1]
            let b = bitmapData[offset+2]
            
            // Ignore transparent or near-transparent pixels
            let a = bitmapData[offset+3]
            if a < 50 { continue }
            
            // Quantize
            let rQ = Int(r) >> quantizationShift
            let gQ = Int(g) >> quantizationShift
            let bQ = Int(b) >> quantizationShift
            
            // Pack into Int key: (R << 12) | (G << 6) | B (assuming 6 bits since 32 levels require 5 bits)
            // 32 levels = 5 bits.
            // Key = (rQ << 10) | (gQ << 5) | bQ
            let key = (rQ << 10) | (gQ << 5) | bQ
            frequency[key, default: 0] += 1
        }
        
        // Find Mode
        guard let maxItem = frequency.max(by: { $0.value < $1.value }) else { return nil }
        
        let key = maxItem.key
        
        // Unpack and De-Quantize (add half bin size to get center)
        // 5 bits mask = 0x1F (31)
        let rQ = (key >> 10) & 0x1F
        let gQ = (key >> 5) & 0x1F
        let bQ = key & 0x1F
        
        // Re-scale to 0-255 range. 
        // value = quant * (256/32) + (step/2)
        // step = 1 << shift = 8
        let step = 1 << quantizationShift
        let halfStep = step / 2
        
        let rFinal = Double(rQ * step + halfStep) / 255.0
        let gFinal = Double(gQ * step + halfStep) / 255.0
        let bFinal = Double(bQ * step + halfStep) / 255.0
        
        return Color(.sRGB, red: rFinal, green: gFinal, blue: bFinal, opacity: 1.0)
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


extension ColorExtractor {
    // CIFilter.paletteCentroid - 使用 K-Means 迭代找出摘要顏色
    /// 從圖片中提取主要顏色
    /// - Parameters:
    ///   - image: 來源 NSImage
    ///   - count: 想要提取的顏色數量 (K值)
    ///   - iterations: 迭代次數 (越多越精準，但也越慢)
    /// - Returns: SwiftUI Color 陣列
    static func extractColors(from image: NSImage, count: Int = 5, iterations: Int = 5) -> [Color] {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let ciImage = CIImage(bitmapImageRep: bitmap) else {
            return []
        }
        
        // 1. 為了效能，先將原圖縮小 (Downsampling)
        // K-Means 在過大的圖片上運算非常昂貴，縮小到 128x128 通常足夠分析色調
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 128.0 / ciImage.extent.width,
                                                                    y: 128.0 / ciImage.extent.height))
        
        // 2. 產生初始種子調色盤 (Random Seed Palette)
        var paletteImage = generateRandomPalette(count: count)
        
        // 3. 建立濾鏡
        let filter = CIFilter.paletteCentroid()
        filter.inputImage = scaledImage
        filter.perceptual = true // 使用感知色彩空間 (更符合人類視覺)
        
        // 4. 迭代運算 (K-Means 收斂過程)
        for _ in 0..<iterations {
            filter.paletteImage = paletteImage
            
            // 取得這一次運算出的新中心點
            if let output = filter.outputImage {
                // 將輸出作為下一次的輸入
                paletteImage = output
            }
        }
        
        // 5. 讀取最終調色盤的顏色數據
        return readColors(from: filter.outputImage!, count: count)
    }
    
    // MARK: - Helper Methods
    
    /// 產生一個 N x 1 的隨機顏色圖片作為種子
    private static func generateRandomPalette(count: Int) -> CIImage {
        var pixelData = [UInt8]()
        for _ in 0..<count {
            pixelData.append(UInt8.random(in: 0...255)) // R
            pixelData.append(UInt8.random(in: 0...255)) // G
            pixelData.append(UInt8.random(in: 0...255)) // B
            pixelData.append(255)                       // A
        }
        
        let data = Data(pixelData)
        return CIImage(bitmapData: data,
                       bytesPerRow: count * 4,
                       size: CGSize(width: count, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
    }
    
    /// 從 CIImage (1 x N strip) 讀取像素值並轉為 Color
    private static func readColors(from image: CIImage, count: Int) -> [Color] {
        let context = CIContext()
        
        // 重要：使用 image.extent 而非固定座標，因為 CIImage 的原點可能不是 (0,0)
        let extent = image.extent
        let width = Int(extent.width)
        let height = Int(extent.height)
        
        // 確保有足夠的 buffer 空間
        var bitmapData = [UInt8](repeating: 0, count: width * height * 4)
        
        // 使用 CIContext 渲染到 buffer，使用正確的 extent
        context.render(image,
                       toBitmap: &bitmapData,
                       rowBytes: width * 4,
                       bounds: extent,  // 使用實際的 extent
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        var colors: [Color] = []
        let actualCount = min(count, width * height)
        for i in 0..<actualCount {
            let offset = i * 4
            let r = Double(bitmapData[offset]) / 255.0
            let g = Double(bitmapData[offset + 1]) / 255.0
            let b = Double(bitmapData[offset + 2]) / 255.0
            
            colors.append(Color(red: r, green: g, blue: b))
        }
        
        return colors
    }
}
