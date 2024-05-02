import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-pdf-page-image' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const RNPdfPageImage = NativeModules.PdfPageImage
  ? NativeModules.PdfPageImage
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const DEFAULT_SCALE = 1.0;

const sanitizeScale = (scale?: number): number => {
  if (scale === undefined) {
    scale = DEFAULT_SCALE;
  }
  return Math.min(Math.max(scale, 0.1), 10.0);
};

export type PageImage = {
  uri: string;
  width: number;
  height: number;
};

export type PdfInfo = {
  uri: string;
  pageCount: number;
};

export default class PdfPageImage {
  static async open(uri: string): Promise<PdfInfo> {
    return RNPdfPageImage.openPdf(uri);
  }

  static async generate(
    uri: string,
    page: number,
    scale?: number
  ): Promise<PageImage> {
    return RNPdfPageImage.generate(uri, page, sanitizeScale(scale));
  }

  static async generateAllPages(
    uri: string,
    scale?: number
  ): Promise<PageImage[]> {
    return RNPdfPageImage.generateAllPages(uri, sanitizeScale(scale));
  }

  static async close(uri: string): Promise<void> {
    return RNPdfPageImage.closePdf(uri);
  }
}
