import { type NativeSyntheticEvent, type ViewProps } from 'react-native';

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
  file = 'file',
}

export type ImageResizeConfig = {
  maxWidth?: number;
  maxHeight?: number;
  quality?: number;
  mode?: 'aspectFit' | 'aspectFill';
};

export interface ViewDropNativeModuleProps {
  onImageReceived: (event: NativeSyntheticEvent<{ image: string }>) => void;
  onDropItemDetected: (event: NativeSyntheticEvent<{}>) => void;
  onVideoReceived: (
    event: NativeSyntheticEvent<{ videoInfo: AvAssetType }>
  ) => void;
  onAudioReceived: (
    event: NativeSyntheticEvent<{ audioInfo: AvAssetType }>
  ) => void;
  onFileReceived: (event: NativeSyntheticEvent<{ fileInfo: FileInfo }>) => void;
  onFileItemsReceived: (event: NativeSyntheticEvent<{ data: string }>) => void;
  fileTypes?: MimeTypes[];
  whiteListExtensions?: string[];
  blackListExtensions?: string[];
  isEnableMultiDropping?: boolean;
  allowPartialDrop?: boolean;
  imageResizeMaxWidth?: number;
  imageResizeMaxHeight?: number;
  imageCompressQuality?: number;
  imageResizeMode?: 'aspectFit' | 'aspectFill';
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
  /**
   * @default false
   * @description
   * When `isEnableMultiDropping` is true, allows the drop session to always be accepted.
   * Files are filtered individually at drop time using blackListExtensions, whiteListExtensions, and fileTypes.
   */
  allowPartialDrop?: boolean;
  imageResize?: ImageResizeConfig;
} & ViewProps;
