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

export type PageImage = {
  uri: string;
  width: number;
  height: number;
};

const sanitizeScale = (scale?: number): number => {
  if (scale === undefined) {
    scale = DEFAULT_SCALE;
  }
  return Math.min(Math.max(scale, 1.0), 10.0);
};

export default class PdfPageImage {

  static async generate(
    filePath: string,
    page: number,
    scale?: number
  ): Promise<PageImage> {
    return RNPdfPageImage.generate(
      filePath,
      page,
      sanitizeScale(scale)
    );
  }

  static async generateAllPages(
    filePath: string,
    scale?: number
  ): Promise<PageImage[]> {
    return RNPdfPageImage.generateAllPages(
      filePath,
      sanitizeScale(scale)
    );
  }
}

