//
//  PdfFlyweight.swift
//  PdfPageImage
//
//  Created by jesus on 01/05/24.
//  Copyright © 2024 Facebook. All rights reserved.
//

import Foundation
import PDFKit
import UIKit

@available(iOS 11.0, *)
class PdfFlyweight {
    
    public let document: PDFDocument
    private var pageCache: [String: [String: Any]] = [:]
    
    init(uri: String) throws {
        self.document = try PdfFlyweight.createDocument(uri: uri)
    }
    
    /**
     Función que obtiene un PDFDocument del URI.
     */
    private static func createDocument(uri: String) throws -> PDFDocument {
        let data: Data

        if uri.hasPrefix("data:") {
            guard let commaIndex = uri.firstIndex(of: ",") else {
                throw NSError(domain: "Header not found in base64 string", code: 500)
            }
            let base64 = uri.suffix(from: uri.index(after: commaIndex))
            guard let decodedData = Data(base64Encoded: String(base64)) else {
                throw NSError(domain: "Failed to decode base64 string", code: 500)
            }
            data = decodedData
            
        } else if uri.hasPrefix("http://") || uri.hasPrefix("https://") || uri.hasPrefix("file://") {
            guard let url = URL(string: uri) else {
                throw NSError(domain: "Invalid URL: \(uri)", code: 400)
            }
            data = try Data(contentsOf: url)
            
        } else {
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: uri) else {
                throw NSError(domain: "File Not Found: \(uri)", code: 404)
            }
            guard let fileData = fileManager.contents(atPath: uri) else {
                throw NSError(domain: "Unable to read file data at \(uri)", code: 500)
            }
            data = fileData
        }

        guard let document = PDFDocument(data: data) else {
            throw NSError(domain: "Data is not a valid PDF", code: 500)
        }
        
        return document
    }

    /**
     Obtiene el numero de paginas
     */
    public func pageCount() -> Int {
        return document.pageCount
    }
    
    /**
     Obtener los límites de la página PDF
     */
    private func bound(pdfPage: PDFPage) -> CGRect {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        // Verificar si las dimensiones deben ser intercambiadas basándonos en la rotación
        let rotationAngle = pdfPage.rotation % 360  // Normalizar el ángulo
        if rotationAngle == 90 || rotationAngle == 270 {
            // Intercambiar las dimensiones si la página está rotada 90 o 270 grados
            return CGRect(x: pageRect.origin.x, y: pageRect.origin.y, width: pageRect.height, height: pageRect.width)
        }
        return pageRect
    }
    
    /**
     Genera una página renderizada del PDF a una imagen, guardándola localmente.
     */
    private func generatePage(
        page: Int,
        scale: CGFloat = 2.0
    ) throws -> [String: Any] {
        
        guard let pdfPage = document.page(at: page) else {
            throw NSError(domain: "Page number \(page) is invalid, file has \(document.pageCount) pages", code: 404)
        }
        
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
        let outputFile = generateOutputFilename()
        
        // Convertir la UIImage escalada a datos PNG
        guard let data = scaledImage.pngData() else {
            throw NSError(domain: "Could not convert image to PNG format", code: 500)
        }
        
        // Write the PNG data to the file system
        try data.write(to: outputFile)
        
        // Return the file URI and dimensions of the output image
        return [
            "uri": outputFile.absoluteString, //"base64": data.base64EncodedString(),
            "width": Int(scaledSize.width),
            "height": Int(scaledSize.height)
        ]
    }
    
    /**
     * Obtiene una página específica, usando caché para mejorar el rendimiento.
     */
    public func getPage(
        index: Int,
        scale: CGFloat = 2.0
    ) throws -> [String: Any] {
        let key = "\(index):\(scale)"
        
        // Verificar si la pagina ya está en la caché
        if let cachedPage = pageCache[key] {
            return cachedPage
        }

        let page = try generatePage(page: index, scale: scale)
        pageCache[key] = page // Guardar la pagina en la caché
        
        return page;
    }
    
    /**
     Genera un nombre de archivo temporal único para almacenar un bitmap.
     */
    private func generateOutputFilename() -> URL {
        // Generar un UUID único
        let uuidString = UUID().uuidString
        
        // Obtener el directorio de documentos de la aplicación
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Error obteniendo el directorio de documentos.")
        }
        
        // Construir el nombre del archivo con el UUID y una extensión
        let filename = "\(uuidString).png"
        
        // Combinar el directorio de documentos con el nombre del archivo para obtener la URL completa
        return documentsDirectory.appendingPathComponent(filename)
    }
       
    /**
     Limpia recursos al cerrar, eliminando archivos temporales y cerrando conexiones.
     */
    public func close() {
        // Recorre todas las páginas almacenadas en la caché
        for (_, pageData) in pageCache {
            if let uriString = pageData["uri"] as? String,
               let uri = URL(string: uriString) {
                // Elimina el archivo correspondiente del sistema de archivos
                do {
                    try FileManager.default.removeItem(at: uri)
                } catch {
                    print("Error al eliminar el archivo: \(error)")
                }
            }
        }
        
        // Limpia la caché después de eliminar todos los archivos
        pageCache.removeAll()
    }
}
