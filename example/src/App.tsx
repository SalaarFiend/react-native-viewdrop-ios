import * as React from 'react';

import { StyleSheet, Text, Image, TouchableOpacity } from 'react-native';
import { ViewDrop } from 'react-native-viewdrop-ios';

export default function App() {
  const [image, setImage] = React.useState('');
  const [videoSource, setVideoSource] = React.useState('');

  const content = React.useMemo(() => {
    if (image) {
      return (
        <Image
          source={{ uri: image.replace(/(\r\n|\n|\r)/gm, '') }}
          style={{
            width: '80%',
            height: '70%',
            borderWidth: 1,
            borderColor: 'pink',
          }}
        />
      );
    } else if (videoSource) {
      return <></>;
      // some video showing
    }
    return <Text>Drop Here Image</Text>;
  }, [image, videoSource]);

  return (
    <ViewDrop
      style={styles.container}
      onImageReceived={setImage}
      onDropItemDetected={() => console.log('DROP START')}
      onVideoReceived={(info) => {
        console.log('INFO:', info);
        setVideoSource(info.fullUrl);
      }}
    >
      {content}
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
    backgroundColor: 'grey',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
