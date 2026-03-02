import React, { type FC, type SyntheticEvent } from 'react';

import { viewDropStyles } from './ViewDrop.styles';
import type {
  AvAssetType,
  FileInfo,
  Props,
  ViewDropNativeModuleProps,
} from './ViewDrop.types';
import { ViewDropModule } from './ViewDropNativeModule';
import { Platform } from 'react-native';

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
    event: SyntheticEvent<undefined, { image: string }>
  ) => {
    if (!onImageReceived) {
      return;
    }
    const image = event.nativeEvent?.image;
    onImageReceived(image);
  };

  const onVideoReceivedEvent = (
    event: SyntheticEvent<undefined, { videoInfo: AvAssetType }>
  ) => {
    if (!onVideoReceived) {
      return;
    }

    const videoInfo = event.nativeEvent?.videoInfo;
    onVideoReceived(videoInfo);
  };

  const onAudioReceivedEvent = (
    event: SyntheticEvent<undefined, { audioInfo: AvAssetType }>
  ) => {
    if (!onAudioReceived) {
      return;
    }

    const audioInfo = event.nativeEvent.audioInfo;
    onAudioReceived(audioInfo);
  };
  const onFileReceivedEvent = (
    event: SyntheticEvent<undefined, { fileInfo: FileInfo }>
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
    console.log('onFileItemsReceived', event.nativeEvent);
    const data = event.nativeEvent.data;
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
