import PDFKit
import UIKit

@objc(PdfPageImage)
class PdfPageImage: NSObject {
    
    @available(iOS 11.0, *)
    func generatePage(
        pdfPage: PDFPage,
        filePath: String,
        page: Int,
        scale: CGFloat = 2.0
    ) throws -> [String: Any] {
        
        // Get the bounds of the PDF page and apply scaling
        let pageRect = pdfPage.bounds(for: .mediaBox)
        
        let scaledRect = CGRect(
              x: pageRect.origin.x * scale,
              y: pageRect.origin.y * scale,
              width: pageRect.width * scale,
              height: pageRect.height * scale)
        
        guard let context = CGContext(data: nil,
           width: Int(scaledRect.width),
           height: Int(scaledRect.height),
           bitsPerComponent: 8,
           bytesPerRow: 0,
           space: CGColorSpaceCreateDeviceRGB(),
           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw NSError(
                domain: "CGContext is null, \(scale) value for scale is invalid", code: 500);
        }
        
        context.interpolationQuality = .high
        
        // Some bitmaps have transparent background. Add a white background.
        context.setFillColor(UIColor.white.cgColor)
        context.fill(scaledRect)
        
        // Apply scaling to the context
        context.scaleBy(x: scale, y: scale)

        // Render the PDF page into the context
        pdfPage.draw(with: .mediaBox, to: context)
        
        // Extract the image
        guard let cgImage = context.makeImage() else {
            throw NSError(
                domain: "ImageContext is null", code: 500);
        }
        
        // Create a UIImage from the CGImage
        let uiImage = UIImage(cgImage: cgImage)
        
        guard let data = uiImage.pngData() else {
            throw NSError(
                domain: "Could not convert image to PNG format", code: 500);
        }
        
        let outputFile = getCachesDirectory()
            .appendingPathComponent(
                getOutputFilename(filePath: filePath, page: page))
        
        try data.write(to: outputFile)
        
        return [
            "uri": outputFile.absoluteString,
            "width": Int(scaledRect.width),
            "height": Int(scaledRect.height),
        ]
    }
    
    @available(iOS 11.0, *)
    @objc(generate:withPage:withScale:withResolver:withRejecter:)
    func generate(
        filePath: String,
        page: Int,
        scale: Float,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
        guard let pdfDocument = getPDFDocument(filePath: filePath) else {
            reject("FILE_NOT_FOUND", "File \(filePath) not found", nil)
            return
        }
        guard let pdfPage = pdfDocument.page(at: page) else {
            reject(
                "INVALID_PAGE", "Page number \(page) is invalid, file has \(pdfDocument.pageCount) pages",
                nil)
            return
        }
        
        do {
            let pageResult = try generatePage(
                pdfPage: pdfPage, filePath: filePath, page: page, scale: CGFloat(scale))
            resolve(pageResult)
            
        } catch {
            reject("INTERNAL_ERROR", error.localizedDescription, nil)
        }
    }
    
    @available(iOS 11.0, *)
    @objc(generateAllPages:withScale:withResolver:withRejecter:)
    func generateAllPages(
        filePath: String,
        scale: Float,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
        guard let pdfDocument = getPDFDocument(filePath: filePath) else {
            reject("FILE_NOT_FOUND", "File \(filePath) not found", nil)
            return
        }
        
        var result: [[String: Any]] = []
        for page in 0 ..< pdfDocument.pageCount {
            guard let pdfPage = pdfDocument.page(at: page) else {
                reject(
                    "INVALID_PAGE", "Page number \(page) is invalid, file has \(pdfDocument.pageCount) pages",
                    nil)
                return
            }
            do {
                let pageResult = try generatePage(
                    pdfPage: pdfPage, filePath: filePath, page: page, scale: CGFloat(scale))
                result.append(pageResult)
            } catch {
                reject("INTERNAL_ERROR", error.localizedDescription, nil)
                return
            }
        }
        resolve(result)
    }
    
    func getPDFDocument(filePath: String) -> PDFDocument? {
        guard let fileUrl = URL(string: filePath) else {
            return nil
        }
        guard let pdfDocument = PDFDocument(url: fileUrl) else {
            return nil;
        }
        return pdfDocument;
    }
    
    func getCachesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getOutputFilename(filePath: String, page: Int) -> String {
        let components = filePath.components(separatedBy: "/")
        var prefix: String
        if let origionalFileName = components.last {
            prefix = origionalFileName.replacingOccurrences(of: ".", with: "-")
        } else {
            prefix = "pdf"
        }
        let random = Int.random(in: 0..<Int.max)
        return "\(prefix)-thumbnail-\(page)-\(random).png"
    }
}
