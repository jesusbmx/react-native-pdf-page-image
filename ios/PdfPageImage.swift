import UIKit
import PDFKit

@objc(PdfPageImage)
class PdfPageImage: NSObject {

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
      let random = Int.random(in: 0 ..< Int.max)
      return "\(prefix)-thumbnail-\(page)-\(random).jpg"
  }

  @available(iOS 11.0, *)
  func generatePage(
      pdfPage: PDFPage,
      filePath: String,
      page: Int,
      scale: CGFloat = 2.0
  ) -> Dictionary<String, Any>?
  {
      // Get the bounds of the PDF page and apply scaling
      let pageRect = pdfPage.bounds(for: .mediaBox)
      let scaledRect = CGRect(x: pageRect.origin.x * scale,
                                    y: pageRect.origin.y * scale,
                                    width: pageRect.width * scale,
                                    height: pageRect.height * scale)
      
      UIGraphicsBeginImageContextWithOptions(scaledRect.size, false, scale)
      guard let context = UIGraphicsGetCurrentContext() else {
          return nil
      }
      
      // Clear the context
      context.clear(scaledRect)
      
      // Some bitmaps have transparent background. Add a white background.
      context.setFillColor(UIColor.white.cgColor)
      context.fill(scaledRect)
      
      // Apply scaling to the context
      context.saveGState()
      context.scaleBy(x: scale, y: scale)
      
      // Render the PDF page into the graphics context
      pdfPage.draw(with: .mediaBox, to: context)
      
      // Restore the context state
      context.restoreGState()

      // Extract the image
      let imageContext = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      guard let image = imageContext else {
          return nil
      }
      
      guard let data = image.pngData() else {
          return nil
      }
      
      do {
          let outputFile = getCachesDirectory()
              .appendingPathComponent(
                getOutputFilename(filePath: filePath, page: page))
          
          try data.write(to: outputFile)
          
          return [
              "uri": outputFile.absoluteString,
              "width": Int(scaledRect.width),
              "height": Int(scaledRect.height),
          ]
      } catch {
          return nil
      }
  }
  
  @available(iOS 11.0, *)
  @objc(generate:withPage:withScale:withResolver:withRejecter:)
  func generate(filePath: String, page: Int, scale: Float, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
      guard let fileUrl = URL(string: filePath) else {
          reject("FILE_NOT_FOUND", "File \(filePath) not found", nil)
          return
      }
      guard let pdfDocument = PDFDocument(url: fileUrl) else {
          reject("FILE_NOT_FOUND", "File \(filePath) not found", nil)
          return
      }
      guard let pdfPage = pdfDocument.page(at: page) else {
          reject("INVALID_PAGE", "Page number \(page) is invalid, file has \(pdfDocument.pageCount) pages", nil)
          return
      }

      if let pageResult = generatePage(pdfPage: pdfPage, filePath: filePath, page: page, scale: CGFloat(scale)) {
          resolve(pageResult)
      } else {
          reject("INTERNAL_ERROR", "Cannot write image data", nil)
      }
  }

  @available(iOS 11.0, *)
  @objc(generateAllPages:withScale:withResolver:withRejecter:)
  func generateAllPages(filePath: String, scale: Float, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
      guard let fileUrl = URL(string: filePath) else {
          reject("FILE_NOT_FOUND", "File \(filePath) not found", nil)
          return
      }
      guard let pdfDocument = PDFDocument(url: fileUrl) else {
          reject("FILE_NOT_FOUND", "File \(filePath) not found", nil)
          return
      }

      var result: [Dictionary<String, Any>] = []
      for page in 0..<pdfDocument.pageCount {
          guard let pdfPage = pdfDocument.page(at: page) else {
              reject("INVALID_PAGE", "Page number \(page) is invalid, file has \(pdfDocument.pageCount) pages", nil)
              return
          }
          if let pageResult = generatePage(pdfPage: pdfPage, filePath: filePath, page: page, scale: CGFloat(scale)) {
              result.append(pageResult)
          } else {
              reject("INTERNAL_ERROR", "Cannot write image data", nil)
              return
          }
      }
      resolve(result)
  }
}
