# react-native-pdf-page-image

This module enables React Native applications to generate images from PDF document pages. It uses PDFKit on iOS and PdfRenderer on Android to render PDF pages as images.

## Installation
```sh
npm install react-native-pdf-page-image
```
#### iOS
`$ cd ios & pod install`

## Usage

Import the module in your code and use the functions to generate images from individual pages or all pages of a PDF document.

```js
import PdfPageImage from 'react-native-pdf-page-image';

const filePath = "content://com.android.providers.downloads.documents/document/msf%3A37";
const scale = 1.0;

// Open a PDF document
PdfPageImage.open(filePath)
  .then(info => console.log(`PDF opened with URI: ${info.uri}, Page count: ${info.pageCount}`))
  .catch(error => console.error('Error opening PDF:', error));

// Generate an image from a specific page
PdfPageImage.generate(filePath, 1, scale)  // Example uses page number 1
  .then(image => console.log(`Generated image: ${image.uri}, Width: ${image.width}, Height: ${image.height}`))
  .catch(error => console.error('Error generating image:', error));

// Generate images from all pages
PdfPageImage.generateAllPages(filePath, scale)
  .then(images => images.forEach((image, index) => console.log(`Page ${index+1}: ${image.uri}, Width: ${image.width}, Height: ${image.height}`)))
  .catch(error => console.error('Error generating images:', error));

// Close the PDF document
PdfPageImage.close(filePath)
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
