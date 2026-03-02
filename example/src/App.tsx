import * as React from 'react';
import { StyleSheet, Text, Image, TouchableOpacity, View } from 'react-native';
import {
  ViewDrop,
  type MapKeysMultiItems,
  type FileInfo,
  type MimeTypes,
} from 'react-native-viewdrop-ios';
//@ts-ignore
import Video from 'react-native-video';

const TYPE_SCENARIO = {
  // ── Single-file mode ──────────────────────────────────────────────────────
  Single: 'single',

  // ── Multi-file, no filters ────────────────────────────────────────────────
  Multi: 'multi',

  // ── Multi-file + blacklist only ───────────────────────────────────────────
  // Strict:  any blacklisted file → whole session rejected (red icon)
  MultiBlacklistStrict: 'multi-blacklist-strict',
  // Partial: blacklisted files silently removed, rest arrives normally
  MultiBlackListPartial: 'multi-blacklist-partial',

  // ── Multi-file + whitelist only ───────────────────────────────────────────
  // Strict:  every file must be in whitelist, else whole session rejected
  MultiWhiteListStrict: 'multi-whitelist-strict',
  // Partial: only whitelisted files arrive, rest silently removed
  MultiWhiteListPartial: 'multi-whitelist-partial',

  // ── Multi-file + fileTypes + whitelist ────────────────────────────────────
  // fileTypes pre-filters by broad Apple UTType category (image/video/audio/file).
  // whiteListExtensions further narrows to specific extensions within that category.
  // Strict:  session rejected if any file fails either filter
  FileTypesWhiteListStrict: 'filetypes-whitelist-strict',
  // Partial: per-file — only files passing both filters reach the callback
  FileTypesWhiteListPartial: 'filetypes-whitelist-partial',

  // ── Multi-file + fileTypes + blacklist ────────────────────────────────────
  // fileTypes limits accepted category; blacklist blocks specific extensions inside it.
  // Strict:  session rejected if any file fails either filter
  FileTypesBlackListStrict: 'filetypes-blacklist-strict',
  // Partial: per-file — blacklisted extensions removed, rest of the category passes
  FileTypesBlackListPartial: 'filetypes-blacklist-partial',

  // ── Image resize ──────────────────────────────────────────────────────────
  // Images are scaled to 800×800 (aspectFit) and compressed at JPEG quality 0.8
  ImageResize: 'image-resize',
} as const;

type Scenario = (typeof TYPE_SCENARIO)[keyof typeof TYPE_SCENARIO];

// ─────────────────────────────────────────────────────────────────────────────
// DEMO CONFIGURATION — uncomment ONE line to activate a scenario
// ─────────────────────────────────────────────────────────────────────────────

// A — Single file: image/video/audio/file each fires its own callback
// const SCENARIO: Scenario = TYPE_SCENARIO.Single;

// B — Multi-drop: any file, no filters
// const SCENARIO: Scenario = TYPE_SCENARIO.Multi;

// C — Multi-drop + blacklist (strict)
// const SCENARIO: Scenario = TYPE_SCENARIO.MultiBlacklistStrict;

// D — Multi-drop + blacklist + allowPartialDrop
const SCENARIO: Scenario = TYPE_SCENARIO.ImageResize;

// E — Multi-drop + whitelist (strict)
// const SCENARIO: Scenario = TYPE_SCENARIO.MultiWhiteListStrict;

// F — Multi-drop + whitelist + allowPartialDrop
// const SCENARIO: Scenario = TYPE_SCENARIO.MultiWhiteListPartial;

// G — fileTypes + whitelist (strict): only PNG/JPEG images, session-level
// const SCENARIO: Scenario = TYPE_SCENARIO.FileTypesWhiteListStrict;

// H — fileTypes + whitelist + allowPartialDrop: PNG/JPEG images filtered per-file
// const SCENARIO: Scenario = TYPE_SCENARIO.FileTypesWhiteListPartial;

// I — fileTypes + blacklist (strict): images only, HEIC blocked at session level
// const SCENARIO: Scenario = TYPE_SCENARIO.FileTypesBlackListStrict;

// J — fileTypes + blacklist + allowPartialDrop: images only, HEIC removed per-file
// const SCENARIO: Scenario = TYPE_SCENARIO.FileTypesBlackListPartial;

// K — image resize: images scaled to 800×800, JPEG quality 0.8
// const SCENARIO: Scenario = TYPE_SCENARIO.ImageResize;

// ─────────────────────────────────────────────────────────────────────────────

type DroppedItem = { label: string; url: string };

export default function App() {
  const [image, setImage] = React.useState('');
  const [videoSource, setVideoSource] = React.useState('');
  const [droppedItems, setDroppedItems] = React.useState<DroppedItem[]>([]);
  const [hint, setHint] = React.useState('Drop a file here');

  // ── Shared helpers ─────────────────────────────────────────────────────────

  const reset = () => {
    console.log('RESET?');
    setImage('');
    setVideoSource('');
    setDroppedItems([]);
    setHint('Drop a file here');
  };

  // Called when a drop session begins (any scenario).
  const handleDropDetected = () => {
    setHint('Receiving…');
    console.log('[ViewDrop] drop session started');
  };

  // ── Single-file callbacks ──────────────────────────────────────────────────

  // Returns the image as a base64 data-URI string.
  const handleImageReceived = (base64: string) => {
    console.log('[ViewDrop] image received (base64 length):', base64.length);
    setImage(base64);
    setHint('Image received');
  };

  // Returns { fileName, fullUrl } — a temporary file path on disk.
  const handleVideoReceived = (info: { fileName: string; fullUrl: string }) => {
    console.log('[ViewDrop] video received:', info.fileName, info.fullUrl);
    setVideoSource(info.fullUrl);
    setHint(`Video: ${info.fileName}`);
  };

  // Returns { fileName, fullUrl } — same shape as video.
  const handleAudioReceived = (info: { fileName: string; fullUrl: string }) => {
    console.log('[ViewDrop] audio received:', info.fileName, info.fullUrl);
    setHint(`Audio: ${info.fileName}`);
  };

  // Fallback for any file type not covered by the callbacks above.
  // Returns { fileName, fileUrl, typeIdentifier }.
  const handleFileReceived = (info: FileInfo) => {
    console.log('[ViewDrop] generic file received:', info);
    setDroppedItems([{ label: info.fileName, url: info.fileUrl }]);
    setHint(`File: ${info.fileName}`);
  };

  // ── Multi-file callback ────────────────────────────────────────────────────

  // Fires when isEnableMultiDropping=true (for any number of files, including 1).
  // `data` is a dictionary keyed by file category: image | video | audio | file.
  // Each value is an array of { fileName, fileUrl, typeIdentifier }.
  const handleFileItemsReceived = (
    data: Record<MapKeysMultiItems, FileInfo[]>
  ) => {
    console.log(
      '[ViewDrop] multi-drop received:',
      JSON.stringify(data, null, 2)
    );

    const items: DroppedItem[] = [];

    if (data.image) {
      data.image.forEach((f) =>
        items.push({ label: `🖼 ${f.fileName}`, url: f.fileUrl })
      );
      // Show the first image if present
      setImage('');
    }
    if (data.video) {
      data.video.forEach((f) =>
        items.push({ label: `🎬 ${f.fileName}`, url: f.fileUrl })
      );
      setVideoSource(data.video[0]!.fileUrl);
    }
    if (data.audio) {
      data.audio.forEach((f) =>
        items.push({ label: `🎵 ${f.fileName}`, url: f.fileUrl })
      );
    }
    if (data.file) {
      data.file.forEach((f) =>
        items.push({ label: `📄 ${f.fileName}`, url: f.fileUrl })
      );
    }

    setDroppedItems(items);
    setHint(`Received ${items.length} file(s)`);
  };

  // ── Scenario props ─────────────────────────────────────────────────────────

  const scenarioProps = (() => {
    switch (SCENARIO) {
      case TYPE_SCENARIO.Single:
        // No isEnableMultiDropping → single-file mode.
        // Each file type fires its own callback.
        return {};

      case TYPE_SCENARIO.Multi:
        // Accept any file; all results go to onFileItemsReceived.
        return { isEnableMultiDropping: true };

      case TYPE_SCENARIO.MultiBlacklistStrict:
        // Strict: if any file in the drag has a blacklisted extension,
        // the entire drop session shows a red "forbidden" indicator.
        return {
          isEnableMultiDropping: true,
          blackListExtensions: ['exe', 'bat', 'sh', 'cmd'],
        };

      case TYPE_SCENARIO.MultiBlackListPartial:
        // Partial: drop is always accepted visually.
        // Blacklisted files are removed from the result silently.
        // Good for mixed drops where the user might include unwanted files.
        return {
          isEnableMultiDropping: true,
          allowPartialDrop: true,
          blackListExtensions: ['exe', 'bat', 'sh', 'cmd'],
        };

      case TYPE_SCENARIO.MultiWhiteListStrict:
        // Strict: EVERY file in the drag must match the whitelist.
        // Even a single non-matching file causes the whole session to be rejected.
        return {
          isEnableMultiDropping: true,
          whiteListExtensions: ['pdf', 'docx', 'txt'],
        };

      case TYPE_SCENARIO.MultiWhiteListPartial:
        // Partial: drop is always accepted.
        // Only files whose extension is in the whitelist reach onFileItemsReceived.
        return {
          isEnableMultiDropping: true,
          allowPartialDrop: true,
          whiteListExtensions: ['pdf', 'docx', 'txt'],
        };

      case TYPE_SCENARIO.FileTypesWhiteListStrict:
        // fileTypes='image' accepts only image UTTypes at the session level.
        // whiteListExtensions further restricts to PNG and JPEG only.
        // If ANY dropped file is not a PNG/JPEG image, the whole session is rejected.
        return {
          isEnableMultiDropping: true,
          fileTypes: ['image'] as MimeTypes[],
          whiteListExtensions: ['png', 'jpg', 'jpeg'],
        };

      case TYPE_SCENARIO.FileTypesWhiteListPartial:
        // Same combination but per-file: drop is always accepted.
        // Only PNG/JPEG images reach onFileItemsReceived; other files are removed silently.
        return {
          isEnableMultiDropping: true,
          allowPartialDrop: true,
          fileTypes: ['image'] as MimeTypes[],
          whiteListExtensions: ['png', 'jpg', 'jpeg'],
        };

      case TYPE_SCENARIO.FileTypesBlackListStrict:
        // fileTypes='image' limits to images; blacklist blocks HEIC specifically.
        // If ANY dropped file is HEIC (or not an image), the whole session is rejected.
        return {
          isEnableMultiDropping: true,
          fileTypes: ['image'] as MimeTypes[],
          blackListExtensions: ['heic', 'heif'],
        };

      case TYPE_SCENARIO.FileTypesBlackListPartial:
        // Same combination but per-file: drop is always accepted.
        // HEIC images are removed from the result; other image formats pass through.
        return {
          isEnableMultiDropping: true,
          allowPartialDrop: true,
          fileTypes: ['image'] as MimeTypes[],
          blackListExtensions: ['heic', 'heif'],
        };

      case TYPE_SCENARIO.ImageResize:
        // Multi-drop with images scaled to 800×800 (aspectFit) and JPEG quality 0.8
        return {
          imageResize: {
            maxWidth: 800,
            maxHeight: 800,
            quality: 0.8,
            mode: 'aspectFill' as const,
          },
        };

      default:
        return {};
    }
  })();

  // ── Render ─────────────────────────────────────────────────────────────────

  const preview = (() => {
    if (image) {
      return (
        <Image
          source={{ uri: image.replace(/(\r\n|\n|\r)/gm, '') }}
          style={styles.preview}
          resizeMode="contain"
        />
      );
    }
    if (videoSource) {
      return (
        <Video
          source={{ uri: videoSource }}
          style={StyleSheet.absoluteFill}
          resizeMode="contain"
        />
      );
    }
    return null;
  })();

  return (
    <ViewDrop
      style={styles.container}
      // ── Scenario-specific props (see switch above) ──
      {...scenarioProps}
      // ── Drop start indicator ──
      onDropItemDetected={handleDropDetected}
      // ── Single-file callbacks (active when isEnableMultiDropping is false) ──
      onImageReceived={handleImageReceived}
      onVideoReceived={handleVideoReceived}
      onAudioReceived={handleAudioReceived}
      onFileReceived={handleFileReceived}
      // ── Multi-file callback (active when isEnableMultiDropping is true) ──
      onFileItemsReceived={handleFileItemsReceived}
    >
      {/* Preview area */}
      <View style={styles.previewArea}>
        {preview ?? <Text style={styles.hint}>{hint}</Text>}
      </View>

      {/* File list for multi-drop results */}
      {droppedItems.length > 0 && (
        <View style={styles.list}>
          {droppedItems.map((item, i) => (
            <Text key={i} style={styles.listItem} numberOfLines={1}>
              {item.label}
            </Text>
          ))}
        </View>
      )}

      {/* Scenario label */}
      <Text style={styles.scenarioLabel}>Scenario: {SCENARIO}</Text>

      {/* Reset button */}
      <TouchableOpacity style={styles.resetBtn} onPress={reset}>
        <Text style={styles.resetText}>Reset</Text>
      </TouchableOpacity>
    </ViewDrop>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#2c2c2e',
  },
  previewArea: {
    width: '80%',
    height: '50%',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#636366',
    borderRadius: 12,
    borderStyle: 'dashed',
    overflow: 'hidden',
    marginBottom: 16,
  },
  preview: {
    width: '100%',
    height: '100%',
  },
  hint: {
    color: '#aeaeb2',
    fontSize: 16,
  },
  list: {
    width: '80%',
    maxHeight: 160,
    marginBottom: 12,
  },
  listItem: {
    color: '#f2f2f7',
    fontSize: 13,
    paddingVertical: 3,
  },
  scenarioLabel: {
    color: '#636366',
    fontSize: 12,
    marginBottom: 12,
  },
  resetBtn: {
    paddingHorizontal: 24,
    paddingVertical: 10,
    backgroundColor: '#3a3a3c',
    borderRadius: 8,
  },
  resetText: {
    color: '#f2f2f7',
    fontSize: 14,
  },
});
