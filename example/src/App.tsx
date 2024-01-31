import * as React from 'react';

import { StyleSheet, Text, Image, TouchableOpacity } from 'react-native';
import { ViewDrop } from 'react-native-viewdrop-ios';

export default function App() {
  const [image, setImage] = React.useState('');
  return (
    <ViewDrop
      style={styles.container}
      onImageReceived={setImage}
      onDropItemDetected={() => console.log('DROP START')}
    >
      {!image ? (
        <Text>Drop Here Image</Text>
      ) : (
        <Image
          source={{ uri: image.replace(/(\r\n|\n|\r)/gm, '') }}
          style={{
            width: '80%',
            height: '70%',
            borderWidth: 1,
            borderColor: 'pink',
          }}
        />
      )}
      {!!image && (
        <TouchableOpacity onPress={() => setImage('')}>
          <Text>Delete Image</Text>
        </TouchableOpacity>
      )}
    </ViewDrop>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
