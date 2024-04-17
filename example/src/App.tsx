import * as React from 'react';
import {
  Button,
  Image,
  StyleSheet,
  Text,
  View,
  ScrollView,
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
      <View style={styles.button}>
        <Button onPress={onPress} title="Pick PDF File" />
      </View>
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
    marginBottom: 40,
  },
  button: {
    margin: 20,
  },
  thumbnailPreview: {
    padding: 0,
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
