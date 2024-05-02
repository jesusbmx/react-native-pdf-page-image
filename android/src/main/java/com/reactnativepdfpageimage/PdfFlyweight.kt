package com.reactnativepdfpageimage

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import com.facebook.react.bridge.ReadableNativeMap
import com.facebook.react.bridge.WritableNativeMap
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.HashMap
import java.util.UUID

/**
 * Clase que implementa el patrón Flyweight para manejar de manera eficiente múltiples objetos PDF.
 */
class PdfFlyweight(private val context: Context, val uriString: String) {
  private val fileDescriptor: ParcelFileDescriptor
  private val pdfRenderer: PdfRenderer
  private var pageCache = HashMap<String, ReadableNativeMap>()

  init {
    val descriptor = context.getParcelFileDescriptor(uriString)
    fileDescriptor = descriptor ?: throw IOException("Uri $uriString not found")
    pdfRenderer = PdfRenderer(fileDescriptor)
  }

  /**
   * Función de extensión para Context que obtiene el descriptor de archivo basado en un URI.
   */
  private fun Context.getParcelFileDescriptor(uriString: String): ParcelFileDescriptor? {
    val uri = Uri.parse(uriString)
    return when {
      uri.scheme in listOf(ContentResolver.SCHEME_CONTENT, ContentResolver.SCHEME_FILE) ->
        contentResolver.openFileDescriptor(uri, "r")
      uriString.startsWith("/") -> {
        val file = File(uriString)
        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
      }
      else -> null
    }
  }

  /**
   * Extensión de Bitmap para almacenar el bitmap como un archivo.
   */
  private fun Bitmap.storeAs(outputFile: File) {
    FileOutputStream(outputFile).use { out ->
      this.compress(Bitmap.CompressFormat.PNG, 100, out)
      this.recycle()
    }
  }

  /**
   * Obtiene el numero de paginas
   */
  fun pageCount(): Int {
    return pdfRenderer.pageCount
  }

  /**
   * Obtine los detalles del pdf
   */
  fun info(): ReadableNativeMap {
    val values = WritableNativeMap()
    values.putString("uri", this.uriString)
    values.putInt("pageCount", this.pageCount())
    return values
  }

  /**
   * Genera una página renderizada del PDF a una imagen, guardándola localmente.
   */
  private fun generatePage(page: Int, scale: Float): ReadableNativeMap {
    if (page < 0 || page >= pdfRenderer.pageCount) {
      throw RuntimeException("Page number $page is invalid, file has ${pdfRenderer.pageCount} pages")
    }

    val currentPage = pdfRenderer.openPage(page)
    val width: Int = (currentPage.width * scale).toInt()
    val height: Int = (currentPage.height * scale).toInt()
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

    // Paint bitmap before rendering
    val canvas = Canvas(bitmap);
    canvas.drawColor(Color.WHITE);
    canvas.drawBitmap(bitmap, 0f, 0f, null);

    // Render Pdf page into bitmap
    currentPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
    currentPage.close()

    // Write file
    val outputFile = generateOutputFilename()
    bitmap.storeAs(outputFile)

    // Result
    val values = WritableNativeMap()
    values.putString("uri", Uri.fromFile(outputFile).toString())
    values.putInt("width", width)
    values.putInt("height", height)
    return values
  }

  /**
   * Obtiene una página específica, usando caché para mejorar el rendimiento.
   */
  fun getPage(index: Int, scale: Float = 2.0f): ReadableNativeMap {
    val key = "($index):($scale)"
    return pageCache.getOrPut(key) { generatePage(index, scale) }
  }

  /**
   * Genera un nombre de archivo temporal único para almacenar un bitmap.
   */
  private fun generateOutputFilename(): File {
    val uuidString = UUID.randomUUID().toString()
    return File.createTempFile(uuidString, ".png", context.cacheDir)
  }

  /**
   * Limpia recursos al cerrar, eliminando archivos temporales y cerrando conexiones.
   */
  fun close() {
    pageCache.values.forEach {
      try {
        File(Uri.parse(it.getString("uri")).path!!).delete()
      } catch (err: Exception) {
        // Log error or handle exception
      }
    }
    pageCache.clear()
    fileDescriptor.close()
    pdfRenderer.close()
  }
}
