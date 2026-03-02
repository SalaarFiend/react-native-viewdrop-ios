# react-native-viewdrop-ios

ViewDrop is a React Native module that turns any `View` into a native iOS drag-and-drop target. Drop images, videos, audio, documents, or any other file — one at a time or in batches.

![Work of library GIF](./assets/WorkOfLib.gif)

---

## Installation

```bash
npm install react-native-viewdrop-ios
# or
yarn add react-native-viewdrop-ios
```

---

## Supported platforms

| Platform | Status |
|----------|--------|
| iOS | ✅ Supported |
| macOS | 🚧 In development |
| Android / Web / tvOS / visionOS | ❌ Not planned |

---

## Quick start

```tsx
import { ViewDrop } from 'react-native-viewdrop-ios';

<ViewDrop
  style={{ flex: 1 }}
  onImageReceived={(base64) => console.log(base64)}
  onDropItemDetected={() => console.log('drag started')}
>
  <Text>Drop files here</Text>
</ViewDrop>
```

---

## Props

### Event callbacks

| Prop | Type | Description |
|------|------|-------------|
| `onDropItemDetected` | `() => void` | Fires when a drag session enters the view. Use it to animate the drop zone. |
| `onImageReceived` | `(image: string) => void` | Fires when a single image is dropped. `image` is a base64 data-URI. Only active when `isEnableMultiDropping` is **false**. |
| `onVideoReceived` | `({ fileName, fullUrl }) => void` | Fires when a single video is dropped. `fullUrl` is a temporary file path. Only active when `isEnableMultiDropping` is **false**. |
| `onAudioReceived` | `({ fileName, fullUrl }) => void` | Fires when a single audio file is dropped. Only active when `isEnableMultiDropping` is **false**. |
| `onFileReceived` | `({ fileName, fileUrl, typeIdentifier }) => void` | Fires for any other file type (PDF, ZIP, etc.) dropped as a single item. Only active when `isEnableMultiDropping` is **false**. |
| `onFileItemsReceived` | `(data: Record<'image'\|'video'\|'audio'\|'file', FileInfo[]>) => void` | Fires when `isEnableMultiDropping` is **true**. Contains all dropped files grouped by category. Works for single-file drops too. |

### Filter props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `fileTypes` | `('image' \| 'video' \| 'audio' \| 'file')[]` | all | Accepted file categories. Uses Apple's UTType system under the hood. |
| `whiteListExtensions` | `string[]` | — | Only files whose extension is in this list are accepted. |
| `blackListExtensions` | `string[]` | — | Files whose extension is in this list are rejected. |
| `isEnableMultiDropping` | `boolean` | `false` | Routes all drops (including single-file) through `onFileItemsReceived`. |
| `allowPartialDrop` | `boolean` | `false` | Requires `isEnableMultiDropping`. Changes filter behaviour from session-level to per-file (see below). |

---

## Filtering in depth

### Session-level vs per-file filtering

By default (`allowPartialDrop = false`) filtering is **session-level**: the entire drop is either accepted or rejected as a unit. If any single dragged item fails a filter, the whole session is rejected and iOS shows a red "forbidden" indicator.

When `allowPartialDrop = true` filtering becomes **per-file**: the drop session is always accepted visually, but individual files that fail the filters are silently removed from the result. This is useful when users drag a mixed batch of files.

```
allowPartialDrop = false (default)          allowPartialDrop = true
─────────────────────────────────           ─────────────────────────────────
[a.pdf, b.exe, c.docx]                      [a.pdf, b.exe, c.docx]
     blackList = ['exe']                          blackList = ['exe']
            │                                            │
     ┌──────▼──────┐                          ┌──────────▼──────────┐
     │  any .exe?  │                          │  filter per file    │
     └──────┬──────┘                          │  a.pdf → ✅ pass    │
           yes                                │  b.exe → ❌ skip    │
            │                                 │  c.docx → ✅ pass   │
     ┌──────▼───────┐                         └──────────┬──────────┘
     │  FORBIDDEN   │                                    │
     │  (grey icon) │                onFileItemsReceived({ file: [a.pdf, c.docx] })
     └──────────────┘
```

### `fileTypes`

Filters by Apple UTType category. If not specified, all types are accepted.

```tsx
// Accept only images and generic documents
<ViewDrop fileTypes={['image', 'file']} ... />
```

### `whiteListExtensions` — allow-list

Only files whose extension is in the list pass. All other extensions are blocked.

```tsx
// Accept only PDF, DOCX, and TXT files
<ViewDrop whiteListExtensions={['pdf', 'docx', 'txt']} ... />
```

With `allowPartialDrop`: non-matching files are silently dropped from the result instead of rejecting the whole session.

### `blackListExtensions` — block-list

Files whose extension matches the list are rejected. All other extensions pass.

```tsx
// Block executables and shell scripts
<ViewDrop blackListExtensions={['exe', 'bat', 'sh', 'cmd']} ... />
```

With `allowPartialDrop`: matching files are removed from the result; the rest are delivered normally.

### Combining filters

All active filters are applied together with **AND** logic. A file must satisfy every specified constraint to pass:

1. File category must match `fileTypes` (if specified)
2. **AND** file extension must be in `whiteListExtensions` (if specified)
3. **AND** file extension must **not** be in `blackListExtensions` (if specified)

#### `fileTypes` + `whiteListExtensions`

`fileTypes` coarsely pre-filters by Apple UTType (image/video/audio/file). `whiteListExtensions` then narrows to specific extensions within that category.

```
fileTypes=['image'] + whiteListExtensions=['png','jpg']
────────────────────────────────────────────────────────
photo.png  → image ✅ → png  ✅ → PASS
photo.heic → image ✅ → heic ❌ → REJECT
doc.pdf    → file  ❌          → REJECT
```

Typical use-cases:
- Accept only raster images, block HEIC/RAW: `fileTypes=['image'] + whiteListExtensions=['png','jpg','jpeg']`
- Accept only specific document formats: `fileTypes=['file'] + whiteListExtensions=['pdf','docx','xlsx']`
- Accept audio but only lossless: `fileTypes=['audio'] + whiteListExtensions=['flac','wav','aiff']`

#### `fileTypes` + `blackListExtensions`

`fileTypes` accepts the whole category; `blackListExtensions` carves out unwanted extensions inside it.

```
fileTypes=['image'] + blackListExtensions=['heic','heif']
──────────────────────────────────────────────────────────
photo.png  → image ✅ → not heic ✅ → PASS
photo.heic → image ✅ → heic     ❌ → REJECT
video.mp4  → video ❌             → REJECT
```

Typical use-cases:
- Accept all images except HEIC: `fileTypes=['image'] + blackListExtensions=['heic','heif']`
- Accept all documents except archives: `fileTypes=['file'] + blackListExtensions=['zip','rar','7z']`

#### All three together

`fileTypes` + `whiteListExtensions` + `blackListExtensions` can be combined, though `whitelist` and `blacklist` on the same extension set is unusual. A more realistic pattern is using `fileTypes` for category selection and one list for extension refinement.

---

## Multi-file dropping

Enable with `isEnableMultiDropping`. All results — even a single-file drop — arrive in `onFileItemsReceived` grouped by category:

```tsx
import { ViewDrop, MapKeysMultiItems, type FileInfo } from 'react-native-viewdrop-ios';

<ViewDrop
  isEnableMultiDropping
  onFileItemsReceived={(data) => {
    // data.image  → FileInfo[]  (PNG, JPEG, HEIC, …)
    // data.video  → FileInfo[]  (MP4, MOV, …)
    // data.audio  → FileInfo[]  (MP3, AAC, …)
    // data.file   → FileInfo[]  (PDF, ZIP, DOCX, …)
    console.log(data);
  }}
/>
```

`FileInfo` shape:
```ts
type FileInfo = {
  fileName: string;       // e.g. "photo.png"
  fileUrl: string;        // absolute path to a temporary copy on disk
  typeIdentifier: string; // UTType category: "image" | "video" | "audio" | "file"
};
```

---

## Examples

### Accept any file — single drop

```tsx
<ViewDrop
  onImageReceived={(base64) => setImage(base64)}
  onVideoReceived={({ fullUrl }) => setVideo(fullUrl)}
  onAudioReceived={({ fullUrl }) => setAudio(fullUrl)}
  onFileReceived={({ fileName, fileUrl }) => console.log(fileName, fileUrl)}
  onDropItemDetected={() => setHint('Drop!')}
/>
```

### Accept any file — multi drop

```tsx
<ViewDrop
  isEnableMultiDropping
  onFileItemsReceived={(data) => {
    data.image?.forEach((f) => console.log('image:', f.fileName));
    data.video?.forEach((f) => console.log('video:', f.fileName));
    data.file?.forEach((f)  => console.log('file:', f.fileName));
  }}
/>
```

### Allow only images (whitelist by type)

```tsx
<ViewDrop
  fileTypes={['image']}
  onImageReceived={(base64) => setImage(base64)}
/>
```

### Allow only PNG and JPEG (whitelist by extension)

If any dragged file is not a PNG or JPEG the whole drop is rejected (red indicator).

```tsx
<ViewDrop
  whiteListExtensions={['png', 'jpg', 'jpeg']}
  onImageReceived={(base64) => setImage(base64)}
/>
```

### Block executables — reject whole batch

```tsx
// If the user drags even one .exe, the entire drop is rejected.
<ViewDrop
  isEnableMultiDropping
  blackListExtensions={['exe', 'bat', 'sh']}
  onFileItemsReceived={(data) => console.log(data)}
/>
```

### Block executables — filter silently (allowPartialDrop)

```tsx
// .exe files are removed; the rest arrive normally.
<ViewDrop
  isEnableMultiDropping
  allowPartialDrop
  blackListExtensions={['exe', 'bat', 'sh']}
  onFileItemsReceived={(data) => console.log(data)}
/>
```

### Accept only PDF from a mixed batch (allowPartialDrop + whitelist)

```tsx
// Drop [a.pdf, b.png, c.txt] → only a.pdf arrives in the callback.
<ViewDrop
  isEnableMultiDropping
  allowPartialDrop
  whiteListExtensions={['pdf']}
  onFileItemsReceived={(data) => {
    // data.file = [{ fileName: 'a.pdf', ... }]
  }}
/>
```

### `fileTypes` + `whiteListExtensions` — only PNG/JPEG images (strict)

The entire drop session is rejected if any file is not a PNG or JPEG image.

```tsx
<ViewDrop
  isEnableMultiDropping
  fileTypes={['image']}
  whiteListExtensions={['png', 'jpg', 'jpeg']}
  onFileItemsReceived={(data) => {
    // data.image contains only PNG/JPEG files
  }}
/>
```

### `fileTypes` + `whiteListExtensions` + `allowPartialDrop` — filter PNG/JPEG per-file

Drop session is always accepted. Non-PNG/JPEG files and non-image files are silently removed from the result.

```tsx
// Drop [photo.png, photo.heic, doc.pdf]
// → onFileItemsReceived receives only photo.png
<ViewDrop
  isEnableMultiDropping
  allowPartialDrop
  fileTypes={['image']}
  whiteListExtensions={['png', 'jpg', 'jpeg']}
  onFileItemsReceived={(data) => {
    // data.image = [{ fileName: 'photo.png', ... }]
  }}
/>
```

### `fileTypes` + `blackListExtensions` — images, but block HEIC (strict)

Drops containing HEIC files or non-image files are rejected at the session level.

```tsx
<ViewDrop
  isEnableMultiDropping
  fileTypes={['image']}
  blackListExtensions={['heic', 'heif']}
  onFileItemsReceived={(data) => {
    // data.image contains any image format except HEIC/HEIF
  }}
/>
```

### `fileTypes` + `blackListExtensions` + `allowPartialDrop` — remove HEIC per-file

Drop session is always accepted. HEIC/HEIF images are filtered out; all other image formats pass through.

```tsx
// Drop [photo.png, photo.heic, shot.heif]
// → onFileItemsReceived receives only photo.png
<ViewDrop
  isEnableMultiDropping
  allowPartialDrop
  fileTypes={['image']}
  blackListExtensions={['heic', 'heif']}
  onFileItemsReceived={(data) => {
    // data.image = [{ fileName: 'photo.png', ... }]
  }}
/>
```

### `fileTypes` + `whiteListExtensions` — documents only (PDF, DOCX, XLSX)

```tsx
<ViewDrop
  isEnableMultiDropping
  fileTypes={['file']}
  whiteListExtensions={['pdf', 'docx', 'xlsx']}
  onFileItemsReceived={(data) => {
    data.file?.forEach((f) => console.log(f.fileName));
  }}
/>
```

---

## Notes

- `onImageReceived`, `onVideoReceived`, `onAudioReceived`, `onFileReceived` are only called when `isEnableMultiDropping` is **false**. When multi-dropping is enabled, use `onFileItemsReceived` for everything.
- `allowPartialDrop` has no effect unless `isEnableMultiDropping` is also enabled.
- `fileUrl` in `FileInfo` is a path to a **temporary** copy of the file. Copy it to a permanent location if you need it after the current run loop.
- Extensions in `whiteListExtensions` / `blackListExtensions` are case-insensitive (`'PDF'` and `'pdf'` are the same).
- `fileTypes` and `whiteListExtensions` / `blackListExtensions` operate on **different mechanisms** and cannot substitute for each other. `fileTypes` uses Apple's UTType conformance system — formats not registered in iOS (e.g. `.ogg`) will never conform to `kUTTypeAudio`, so adding `'ogg'` to `whiteListExtensions` will not help when `fileTypes=['audio']` is set. For non-standard or niche formats, omit `fileTypes` entirely and rely solely on `whiteListExtensions` to control what is accepted.

---

## Future plans

- Image resize settings before delivery
- Drop preview / badge customisation
- macOS support
- Fabric / New Architecture support

---

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
