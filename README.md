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

<ViewDrop style={styles.container} onImageReceived={setImage}>
  // your views
</ViewDrop>;
```

| Method          | Description                     |
| --------------- | ------------------------------- |
| onImageReceived | (image : base64_string) => void |

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
