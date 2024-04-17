import PDFKit
import UIKit

@objc(PdfPageImage)
class PdfPageImage: NSObject {
    
    // Obtener los límites de la página PDF
    @available(iOS 11.0, *)
    func bound(pdfPage: PDFPage) -> CGRect {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        
        // Verificar si las dimensiones deben ser intercambiadas basándonos en la rotación
        let rotationAngle = pdfPage.rotation % 360  // Normalizar el ángulo
        if rotationAngle == 90 || rotationAngle == 270 {
            // Intercambiar las dimensiones si la página está rotada 90 o 270 grados
            return CGRect(x: pageRect.origin.x, y: pageRect.origin.y, width: pageRect.height, height: pageRect.width)
        }
        
        return pageRect
    }
    
    @available(iOS 11.0, *)
    func generatePage(
        pdfPage: PDFPage,
        filePath: String,
        page: Int,
        scale: CGFloat = 2.0
    ) throws -> [String: Any] {
        
        // Obtener los límites de la página PDF
        var pageRect = bound(pdfPage: pdfPage);
        
        // Definir el tamaño escalado en base al factor de escala deseado
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale)
        
        // Utilizar UIGraphicsImageRenderer para manejar el escalado y la creación de la imagen
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        
        // Renderizar la imagen utilizando el bloque de UIGraphicsImageRenderer
        let scaledImage = renderer.image { context in
            context.cgContext.interpolationQuality = .high
            
            // Establecer un fondo blanco
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: scaledSize))
            
            // Dibujar la página en el contexto
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0) // Invertir la imagen en el eje y
            
            // Ajustar la rotación en caso de que la página esté en orientación horizontal
            /*let rotationAngle = pdfPage.rotation
            if rotationAngle == 90 {
                context.cgContext.translateBy(x: scaledSize.width, y: 0)
                context.cgContext.rotate(by: .pi / 2)  // Rotar 90 grados
            } else if rotationAngle == 270 {
                context.cgContext.translateBy(x: 0, y: scaledSize.height)
                context.cgContext.rotate(by: -(.pi / 2))  // Rotar -90 grados
            } else if rotationAngle == 180 {
                context.cgContext.translateBy(x: scaledSize.width, y: scaledSize.height)
                context.cgContext.rotate(by: .pi)  // Rotar 180 grados
            }*/
            
            // Especificar claramente cómo debe manejarse el renderizado del PDF
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }
        
        /*
        // Definir el tamaño escalado en base al factor de escala deseado
            // Multiplicamos el factor de escala por 2 para compensar la menor resolución de la miniatura
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale)
        
        let scaledImage = pdfPage.thumbnail(of: scaledSize, for: .mediaBox)
        */
        
        
        // Determine the output file path
        let outputFile = getCachesDirectory()
            .appendingPathComponent(
                getOutputFilename(filePath: filePath, page: page))
        
        // Convertir la UIImage escalada a datos PNG
        guard let data = scaledImage.pngData() else {
            throw NSError(
                domain: "Could not convert image to PNG format", code: 500)
        }
        
        // Write the PNG data to the file system
        try data.write(to: outputFile)
        
        // Return the file URI and dimensions of the output image
        return [
            "uri": outputFile.absoluteString,
            //"base64": data.base64EncodedString(),
            "width": Int(scaledSize.width),
            "height": Int(scaledSize.height)
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
    
    @available(iOS 11.0, *)
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
