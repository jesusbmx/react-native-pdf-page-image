package com.reactnativepdfpageimage

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import java.io.IOException

class PdfPageImageModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

  private var pdfCache = HashMap<String, PdfFlyweight>()

  override fun getName(): String {
    return "PdfPageImage"
  }

  /**
   * Opens a PDF from the provided URI.
   */
  @ReactMethod
  fun openPdf(uri: String, promise: Promise) {
    try {
      val pdf = getPdf(uri)
      val info = pdf.info()

      val target = WritableNativeMap()
      target.merge(info)
      promise.resolve(target)

    } catch (ex: IOException) {
      promise.reject("INTERNAL_ERROR", ex)
    }
  }

  /**
   * Generates an image for a specific page at the specified scale.
   */
  @ReactMethod
  fun generate(uri: String, page: Int, scale: Float, promise: Promise) {
    try {
      val pdf = getPdf(uri)
      val pageResult = pdf.getPage(page, scale)

      val target = WritableNativeMap()
      target.merge(pageResult)
      promise.resolve(target)

    } catch (ex: IOException) {
      promise.reject("INTERNAL_ERROR", ex)
    }
  }

  /**
   * Generates images for all pages of a PDF at the specified scale.
   */
  @ReactMethod
  fun generateAllPages(uri: String, scale: Float, promise: Promise) {
    try {
      val pdf = getPdf(uri)

      val result = WritableNativeArray()
      for (page in 0 until pdf.pageCount()) {
        val target = WritableNativeMap()
        target.merge(pdf.getPage(page, scale))
        result.pushMap(target)
      }
      promise.resolve(result)

    } catch (ex: IOException) {
      promise.reject("INTERNAL_ERROR", ex)
    }
  }

  /**
   * Closes the PDF resource associated with the given URI.
   */
  @ReactMethod
  fun closePdf(uri: String, promise: Promise) {
    try {
      val pdf = pdfCache.remove(uri)
      if (pdf != null) {
        pdf.close()
      }
      promise.resolve(null)

    } catch (ex: IOException) {
      promise.reject("INTERNAL_ERROR", ex)
    }
  }

  /**
   * Retrieves or creates a PdfFlyweight object for the given URI.
   */
  private fun getPdf(uri: String): PdfFlyweight {
    return pdfCache.getOrPut(uri) { PdfFlyweight(reactApplicationContext, uri) }
  }

}
