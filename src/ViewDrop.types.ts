import { type SyntheticEvent } from 'react';
import { type ViewProps } from 'react-native';

export type AvAssetType = {
  fullUrl: string;
  fileName: string;
};

export type MimeTypes = 'image' | 'video' | 'audio' | 'file';

export type FileInfo = {
  fileName: string;
  fileUrl: string;
  typeIdentifier: string;
};

export enum MapKeysMultiItems {
  video = 'video',
  audio = 'audio',
  image = 'image',
  otherFiles = 'otherFiles',
}

export interface ViewDropNativeModuleProps {
  onImageReceived: (
    event: SyntheticEvent<undefined, { image: string }>
  ) => void;
  onDropItemDetected: (event: SyntheticEvent) => void;
  onVideoReceived: (
    event: SyntheticEvent<undefined, { videoInfo: AvAssetType }>
  ) => void;
  onAudioReceived: (
    event: SyntheticEvent<undefined, { audioInfo: AvAssetType }>
  ) => void;
  onFileReceived: (
    event: SyntheticEvent<undefined, { fileInfo: FileInfo }>
  ) => void;
  onFileItemsReceived: (
    event: SyntheticEvent<
      undefined,
      { data: Record<MapKeysMultiItems, FileInfo[]> }
    >
  ) => void;
  fileTypes?: MimeTypes[];
  whiteListExtensions?: string[];
  blackListExtensions?: string[];
  isEnableMultiDropping?: boolean;
}

export type Props = {
  onImageReceived?: (image: string) => void;
  onDropItemDetected?: () => void;
  onVideoReceived?: (videoInfo: AvAssetType) => void;
  onAudioReceived?: (audioInfo: AvAssetType) => void;
  onFileReceived?: (audioInfo: FileInfo) => void;
  onFileItemsReceived?: (data: Record<MapKeysMultiItems, FileInfo[]>) => void;
  fileTypes?: MimeTypes[];
  whiteListExtensions?: string[];
  blackListExtensions?: string[];
  isEnableMultiDropping?: boolean;
} & ViewProps;
