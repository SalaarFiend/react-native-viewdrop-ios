# react-native-viewdrop-ios

ViewDrop is a module for React Native that will allow View to use a native iOS feature to transfer pictures, videos, files, and more through a simple Drag & Drop action.

![Work of library GIF](./assets/WorkOfLib.gif)

## Installation

```bash
npm install react-native-viewdrop-ios
```

```bash
yarn add react-native-viewdrop-ios
```

## Supported platforms
Now this native Apple System feature only.

- [x] iOS
- [ ] macOS - on development

**Platforms that will not be supported unless they have native features on them**
- [ ] tvOS
- [ ] visionOS
- [ ] Android
- [ ] Windows
- [ ] Web

## Usage

Simply wrap your view for enable iOS native feature!

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
    fileTypes={['image', 'audio']}
    whiteListExtensions={['png', 'jpeg']}
    blackListExtensions={['mp3']}
>
  // your views
</ViewDrop>;
```

| Prop             | Description                     |
| ------------------ | ------------------------------- |
| onImageReceived    | ( image : base64_string ) => void |
| onDropItemDetected | () => void                      |
| onVideoReceived    | ( fileName : string, fullUrl : string ) => void                      |
| onAudioReceived    | ( fileName : string, fullUrl : string ) => void                      |
| fileTypes          | 'image' ,'video','audio'       |
| whiteListExtensions          | string[]       |
| blackListExtensions          | string[]       |


## Props

### fileTypes
Array of allowed file types. Supports following values:
- `'image'` - allows image files
- `'video'` - allows video files
- `'audio'` - allows audio files

```typescript
fileTypes?: ('image' | 'video' | 'audio')[]
```

### whiteListExtensions
Array of allowed file extensions. Only files with specified extensions will be accepted. If not provided, all extensions are allowed (within fileTypes constraints if specified).

```typescript
whiteListExtensions?: string[]
```

### blackListExtensions
Array of forbidden file extensions. Files with specified extensions will be rejected. If not provided, no extensions are blocked.

```typescript
blackListExtensions?: string[]
```

## Examples

### Basic usage with file types
```typescript
import ViewDrop from 'react-native-view-drop';

// Allow only images and videos
<ViewDrop fileTypes={['image', 'video']} />
```

### Using white list extensions
```typescript
// Allow only PNG and JPG files
<ViewDrop whiteListExtensions={['png', 'jpg', 'jpeg']} />

// Allow only PNG and JPG images
<ViewDrop
  fileTypes={['image']}
  whiteListExtensions={['png', 'jpg', 'jpeg']}
/>
```

### Using black list extensions
```typescript
// Block specific file types
<ViewDrop blackListExtensions={['exe', 'bat', 'sh']} />
```

### Combining white and black lists
```typescript
// Allow PNG and JPG, but block HEIC
<ViewDrop
  whiteListExtensions={['png', 'jpg', 'jpeg']}
  blackListExtensions={['heic']}
/>
```

### Priority and combinations
- If only `fileTypes` is specified, any file of those types is allowed
- If `whiteListExtensions` is specified, only files with listed extensions are allowed
- If `blackListExtensions` is specified, files with listed extensions are blocked
- When combining multiple constraints:
  - File must match `fileTypes` (if specified)
  - AND must match `whiteListExtensions` (if specified)
  - AND must not match `blackListExtensions` (if specified)


## Notes
- If you want restrict or add file such as doc,txt, pdf and e.t.c - should use combination of `whileListExtensions` and `blackListExtensions`.
- If you don't care about specific file extensions within images, video, audio - you should ONLY use the `fileTypes` field. Apple's generalized types are used there
- If you want add some specific type to `fileTypes`, for example `.ogg` for audio. You should use combination of `fileTypes` and `whiteListExtensions` :
```
 <ViewDrop
      style={styles.container}
      ... other props
      fileTypes={['image', 'audio']}
      // in this example whileListExtensions works as a type set extender
      whiteListExtensions={['ogg']}
    >
```


## Future Plans

- Settings for resize images
- Works with preview of dropping
- Works with multiple files drop
- MacOS supports
- Fabric supports

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
