# react-native-pdf-page-image

This module enables React Native applications to generate images from PDF document pages. It uses PDFKit on iOS and PdfRenderer on Android to render PDF pages as images.

## Installation
```sh
npm install react-native-pdf-page-image
```
#### iOS
`$ cd ios && pod install`

## Testing the example app

Run these from the repo root (the folder that contains `package.json` and the `example` directory). One command per line.

```bash
npm install
npm run example:install
npm run example:pods
cd example && npx react-native run-ios
```

For Android, from repo root:

```bash
cd example && npx react-native run-android
```

Or from inside `example` after install: `npm run pods` (installs iOS pods), then `npm run ios` or `npm run android`.

**iOS: "Error installing boost" or "Unrecognized archive format"**  
The example Podfile forces the boost pod to use the official Boost mirror. If `pod install` still fails, clear the boost cache and reinstall:

```bash
cd example/ios
pod cache clean boost
rm -rf Pods Podfile.lock build
pod install
cd ../..
```

Then run the app from the repo root: `cd example && npx react-native run-ios`.

## Usage

Importing the Module
```js
import PdfPageImage from 'react-native-pdf-page-image';
```


### Generating Images for All PDF Pages

You can generate images for all pages in a PDF document with the following method:
```js
const uri = "https://pdfobject.com/pdf/sample.pdf";
const scale = 1.0;

// Generate images from all pages
PdfPageImage.generateAllPages(uri, scale)
  .then(images => images.forEach((image, index) => console.log(`Page ${index+1}: ${image.uri}, Width: ${image.width}, Height: ${image.height}`)))
  .catch(error => console.error('Error generating images:', error));

```


### Generating an Image for a Specific Page

If you only need to generate an image for a single page, use the generate method:
```js
const uri = "https://pdfobject.com/pdf/sample.pdf";
const scale = 1.0;

// Generate an image from a specific page
PdfPageImage.generate(uri, 1, scale)  // Example uses page number 1
  .then(image => console.log(`Generated image: ${image.uri}, Width: ${image.width}, Height: ${image.height}`))
  .catch(error => console.error('Error generating image:', error));
```


### Optional: Getting PDF Information

To open a PDF document and retrieve its information, use the open method:
```js
PdfPageImage.open(uri)
  .then(info => console.log(`PDF opened with URI: ${info.uri}, Page count: ${info.pageCount}`))
  .catch(error => console.error('Error opening PDF:', error));
```


### Optional: Closing the PDF Document

After processing, you can close the PDF document and delete any temporary files that were generated. Use the close method:
```js
PdfPageImage.close(uri)
  .then(() => console.log('PDF closed successfully.'))
  .catch(error => console.error('Error closing PDF:', error));
```

# API

`open(uri: string): Promise<PdfInfo>`

  Opens a PDF document and returns its basic information.
  - uri: Path to the PDF file.

`generate(uri: string, page: number, scale?: number): Promise<PageImage>`

  Generates an image from a specific PDF page.
  - uri: Path to the PDF file.
  - page: Page number to render.
  - scale: Scale of the generated image, optional

`generateAllPages(uri: string, scale?: number): Promise<PageImage[]>`

  Generates images from all pages of the PDF document.
  - uri: Path to the PDF file.
  - scale: Scale of the generated images, optional.

`close(uri: string): Promise<void>`

  Clean up resources, deleting temporary files and closing connections..
  - uri: Path to the PDF file that is currently open.

# Types

```typescript
type PdfInfo = {
  uri: string;
  pageCount: number;
};

type PageImage = {
  uri: string;
  width: number;
  height: number;
};
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
