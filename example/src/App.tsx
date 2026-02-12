import * as React from 'react';
import {
  Button,
  Image,
  StyleSheet,
  Text,
  View,
  ScrollView,
  SafeAreaView,
} from 'react-native';
import DocumentPicker from 'react-native-document-picker';
//import PdfPageImage, { PageImage } from 'react-native-pdf-page-image';
import PdfPageImage, { PageImage } from '../../';

type ErrorType = { code: string; message: string };

export default function App() {
  const [thumbnail, setThumbnail] = React.useState<PageImage | undefined>();

  const [error, setError] = React.useState<ErrorType | undefined>();

  const onPress = async () => {
    try {
      const { uri } = await DocumentPicker.pickSingle({
        type: [DocumentPicker.types.pdf],
      });
      const result = await PdfPageImage.generate(uri, 0, 1.0);
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

  /*const onPress = async () => {
    try {
      const uri  = "https://pdfobject.com/pdf/sample.pdf"
      const result = await PdfPageImage.generate(uri, 0, 1.0);
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
  };*/

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
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <Text style={styles.title}>PDF Page Image</Text>
        <Text style={styles.subtitle}>
          Tap the button to pick a PDF and generate a thumbnail
        </Text>
        <View style={styles.button}>
          <Button onPress={onPress} title="Pick PDF File" />
        </View>
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
        >
          <View style={styles.thumbnailPreview}>
            {ThumbnailResult}
            {ThumbnailError}
          </View>
        </ScrollView>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  container: {
    flex: 1,
    alignItems: 'center',
    paddingTop: 16,
    marginBottom: 40,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#111',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: '#333',
    marginBottom: 16,
    textAlign: 'center',
  },
  button: {
    margin: 20,
  },
  scroll: {
    flex: 1,
    alignSelf: 'stretch',
  },
  scrollContent: {
    paddingBottom: 40,
  },
  thumbnailPreview: {
    padding: 16,
    alignItems: 'center',
  },
  thumbnailImage: {
    width: '100%',
    borderColor: '#000',
    borderWidth: 1,
    backgroundColor: '#eee',
  },
  thumbnailInfo: {
    color: 'darkblue',
    padding: 10,
  },
  thumbnailError: {
    color: 'crimson',
  },
});
