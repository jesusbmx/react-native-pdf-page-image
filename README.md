# react-native-pdf-page-image
Library to obtain the pages of a pdf in image format
## Installation

```sh
npm install react-native-pdf-page-image
```

## Usage

```js
import PdfPageImage, { PageImage } from 'react-native-pdf-page-image';

// For iOS, the filePath can be a file URL.
// For Android, the filePath can be either a content URI, a file URI or an absolute path.
const filePath = 'file:///mnt/sdcard/myDocument.pdf';
const page = 0;
const scale = 2.0;

// The thumbnail image is stored in caches directory, file uri is returned.
// Image dimensions are also available to help you display it correctly.
const { uri, width, height } = await PdfPageImage.generate(filePath, page);

// Generate thumbnails for all pages, returning an array of the object above.
const results = await PdfPageImage.generateAllPages(filePath);

// Default scale is 2.0, you can optionally specify a scale
const { uri, width, height } = await PdfPageImage.generate(filePath, page, scale);
const results = await PdfPageImage.generateAllPages(filePath, scale);
```

## Example
```js
import * as React from 'react';
import { Button, Image, StyleSheet, Text, View, ScrollView } from 'react-native';
import DocumentPicker from 'react-native-document-picker';
import PdfPageImage, { PageImage } from 'react-native-pdf-page-image';

type ErrorType = { code: string; message: string };

export default function App() {

  const [thumbnail, setThumbnail] = 
    React.useState<PageImage | undefined>();

  const [error, setError] = 
    React.useState<ErrorType | undefined>();

  const onPress = async () => {
    try {
      const { uri } = await DocumentPicker.pickSingle({
        type: [DocumentPicker.types.pdf],
      });
      const result = await PdfPageImage.generate(uri, 0, 2.0);
      setThumbnail(result);
      setError(undefined);

    } catch (err) {
      if (DocumentPicker.isCancel(err)) {
        // User cancelled the picker, exit any dialogs or menus and move on
      } else {
        setThumbnail(undefined);
        setError(err as ErrorType);
      }
    }
  };

  const ThumbnailResult = thumbnail ? (
    <>
      <Image
        source={thumbnail}
        resizeMode="contain"
        style={styles.thumbnailImage}
      />
      <Text style={styles.thumbnailInfo}>uri: {thumbnail.uri}</Text>
      <Text style={styles.thumbnailInfo}>width: {thumbnail.width}</Text>
      <Text style={styles.thumbnailInfo}>height: {thumbnail.height}</Text>
    </>
  ) : null;

  const ThumbnailError = error ? (
    <>
      <Text style={styles.thumbnailError}>Error code: {error.code}</Text>
      <Text style={styles.thumbnailError}>Error message: {error.message}</Text>
    </>
  ) : null;

  return (
    <View style={styles.container}>
      <Button onPress={onPress} title="Pick PDF File" />
      <ScrollView>
        <View style={styles.thumbnailPreview}>
          {ThumbnailResult}
          {ThumbnailError}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  thumbnailPreview: {
    padding: 20,
    alignItems: 'center',
  },
  thumbnailImage: {
    width: 500,
    height: 500,
    marginBottom: 20,
  },
  thumbnailInfo: {
    color: 'darkblue',
  },
  thumbnailError: {
    color: 'crimson',
  },
});
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
