
import UIKit

@available(iOS 11.0, *)
@objc(PdfPageImage)
class PdfPageImage: NSObject {
    
    private var documentCache: [String: PdfFlyweight] = [:]
    
    @available(iOS 11.0, *)
    @objc(openPdf:withResolver:withRejecter:)
    func openPdf(
        uri: String,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
        do {
            let pdf = try getPdfFlyweight(uri: uri)
            resolve([
                "uri": uri,
                "pageCount": pdf.pageCount(),
            ])
            
        } catch {
            reject("INTERNAL_ERROR", error.localizedDescription, nil)
        }
    }
    
    @available(iOS 11.0, *)
    @objc(generate:withPage:withScale:withResolver:withRejecter:)
    func generate(
        uri: String,
        page: Int,
        scale: Float,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
        do {
            let pdf = try getPdfFlyweight(uri: uri)
            let pageResult = try pdf.getPage(
                page: page,
                scale: CGFloat(scale)
            )
            resolve(pageResult)
            
        } catch {
            reject("INTERNAL_ERROR", error.localizedDescription, nil)
        }
    }

    @available(iOS 11.0, *)
    @objc(generateAllPages:withScale:withResolver:withRejecter:)
    func generateAllPages(
        uri: String,
        scale: Float,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
            
        do {
            var result: [[String: Any]] = []
            let pdf = try getPdfFlyweight(uri: uri)
            
            for page in 0 ..< pdf.pageCount() {
                let pageResult = try pdf.getPage(
                    page: page,
                    scale: CGFloat(scale)
                )
                result.append(pageResult)
            }
            resolve(result)
            
        } catch {
            reject("INTERNAL_ERROR", error.localizedDescription, nil)
            return
        }
    }
    
    @available(iOS 11.0, *)
    @objc(closePdf:withResolver:withRejecter:)
    func closePdf(
        uri: String,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
        do {
            if let pdf = documentCache.removeValue(forKey: uri) {
                pdf.close()
            }
            resolve(nil)
            
        } catch {
            reject("INTERNAL_ERROR", error.localizedDescription, nil)
        }
    }
    
    @available(iOS 11.0, *)
    func getPdfFlyweight(uri: String) throws -> PdfFlyweight {
        // Verificar si el documento ya está en la caché
        if let cachedDocument = documentCache[uri] {
            return cachedDocument
        }

        let pdfDocument = try PdfFlyweight(uri: uri);
        documentCache[uri] = pdfDocument  // Guardar el documento en la caché
        
        return pdfDocument;
    }
    
}
