# react-native-viewdrop-ios

ViewDrop is a module for React Native that will allow View to use a native iOS feature to transfer pictures, videos, files, and more through a simple Drag & Drop action.

## Installation

```sh
npm install react-native-viewdrop-ios
```

## Usage

```js
import { ViewDrop } from 'react-native-viewdrop-ios';

// ...

<ViewDrop style={styles.container}
    onImageReceived={setImage}
    onDropItemDetected={() => some logic for start dropping}
    onVideoReceived={({fileName : string, fullUrl : string}) => {
      some logic with path of video file
    }}
    onAudioReceived={({fileName : string, fullUrl : string}) => {
      some logic with path of audio file
    }}
>
  // your views
</ViewDrop>;
```

| Method             | Description                     |
| ------------------ | ------------------------------- |
| onImageReceived    | ( image : base64_string ) => void |
| onDropItemDetected | () => void                      |
| onVideoReceived    | ( fileName : string, fullUrl : string ) => void                      |
| onAudioReceived    | ( fileName : string, fullUrl : string ) => void                      |


## Future Plans

- Add file drops (such as doc, txt, pdf e.t.c.)
- Add option like whiteList for dropping to view
- Settings for resize images
- Maybe whiteList for extensions of files (jpeg,png,mov e.t.c.)

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
