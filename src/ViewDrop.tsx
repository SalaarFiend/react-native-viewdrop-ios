import React, { type FC } from 'react';
import { Platform, type NativeSyntheticEvent } from 'react-native';

import { viewDropStyles } from './ViewDrop.styles';
import {
  MapKeysMultiItems,
  type AvAssetType,
  type FileInfo,
  type Props,
  type ViewDropNativeModuleProps,
} from './ViewDrop.types';
import { ViewDropModule } from './ViewDropNativeModule';

export const ViewDrop: FC<Props> = ({
  children,
  onImageReceived,
  onDropItemDetected,
  onVideoReceived,
  onAudioReceived,
  onFileReceived,
  onFileItemsReceived,
  fileTypes,
  whiteListExtensions,
  blackListExtensions,
  isEnableMultiDropping,
  allowPartialDrop,
  imageResize,
  ...props
}) => {
  const {
    maxWidth: imageResizeMaxWidth = 0,
    maxHeight: imageResizeMaxHeight = 0,
    quality: imageCompressQuality = 1.0,
    mode: imageResizeMode = 'aspectFit',
  } = imageResize ?? {};
  const onImageReceivedEvent = (
    event: NativeSyntheticEvent<{ image: string }>
  ) => {
    if (!onImageReceived) {
      return;
    }
    const image = event.nativeEvent?.image;
    onImageReceived(image);
  };

  const onVideoReceivedEvent = (
    event: NativeSyntheticEvent<{ videoInfo: AvAssetType }>
  ) => {
    if (!onVideoReceived) {
      return;
    }

    const videoInfo = event.nativeEvent?.videoInfo;
    onVideoReceived(videoInfo);
  };

  const onAudioReceivedEvent = (
    event: NativeSyntheticEvent<{ audioInfo: AvAssetType }>
  ) => {
    if (!onAudioReceived) {
      return;
    }

    const audioInfo = event.nativeEvent.audioInfo;
    onAudioReceived(audioInfo);
  };
  const onFileReceivedEvent = (
    event: NativeSyntheticEvent<{ fileInfo: FileInfo }>
  ) => {
    if (!onFileReceived) {
      return;
    }

    const fileInfo = event.nativeEvent.fileInfo;
    onFileReceived(fileInfo);
  };

  const onDropItemDetectedEvent = () => {
    if (!onDropItemDetected) {
      return;
    }

    onDropItemDetected();
  };
  const onFileItemsReceivedEvent = (
    event: Parameters<ViewDropNativeModuleProps['onFileItemsReceived']>[0]
  ) => {
    if (!onFileItemsReceived) {
      return;
    }
    const parsed = JSON.parse(event.nativeEvent.data) as Record<
      string,
      FileInfo[]
    >;
    const data = {} as Record<MapKeysMultiItems, FileInfo[]>;
    if (parsed.image?.length) {
      data[MapKeysMultiItems.image] = parsed.image;
    }
    if (parsed.video?.length) {
      data[MapKeysMultiItems.video] = parsed.video;
    }
    if (parsed.audio?.length) {
      data[MapKeysMultiItems.audio] = parsed.audio;
    }
    if (parsed.file?.length) {
      data[MapKeysMultiItems.file] = parsed.file;
    }
    onFileItemsReceived(data);
  };

  if (Platform.OS === 'android') {
    return <>{children}</>;
  }

  return (
    <ViewDropModule
      style={viewDropStyles.viewDrop}
      {...props}
      onImageReceived={onImageReceivedEvent}
      onDropItemDetected={onDropItemDetectedEvent}
      onVideoReceived={onVideoReceivedEvent}
      onAudioReceived={onAudioReceivedEvent}
      onFileReceived={onFileReceivedEvent}
      whiteListExtensions={whiteListExtensions}
      blackListExtensions={blackListExtensions}
      fileTypes={fileTypes}
      isEnableMultiDropping={isEnableMultiDropping}
      allowPartialDrop={allowPartialDrop}
      imageResizeMaxWidth={imageResizeMaxWidth}
      imageResizeMaxHeight={imageResizeMaxHeight}
      imageCompressQuality={imageCompressQuality}
      imageResizeMode={imageResizeMode}
      onFileItemsReceived={onFileItemsReceivedEvent}
    >
      {children}
    </ViewDropModule>
  );
};
