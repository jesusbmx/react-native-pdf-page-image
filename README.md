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

// Generate an image from a specific page
PdfPageImage.generate(filePath, pageNumber, scale)
  .then(image => {
    console.log(image.uri);
    console.log(`Width: ${image.width}, Height: ${image.height}`);
  })
  .catch(error => {
    console.error(error);
  });

// Generate images from all pages
PdfPageImage.generateAllPages(filePath, scale)
  .then(images => {
    images.forEach(image => {
      console.log(image.uri);
      console.log(`Width: ${image.width}, Height: ${image.height}`);
    });
  })
  .catch(error => {
    console.error(error);
  });
```


# API

`generate(filePath: string, page: number, scale?: number): Promise<PageImage>`

  Generates an image from a specific PDF page.
  - filePath: Path to the PDF file.
  - page: Page number to render.
  - scale: Scale of the generated image, optional

`generateAllPages(filePath: string, scale?: number): Promise<PageImage[]>`

  Generates images from all pages of the PDF document.
  - filePath: Path to the PDF file.
  - scale: Scale of the generated images, optional.

# Types

```typescript
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
