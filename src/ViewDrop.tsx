import React, { type FC, type SyntheticEvent } from 'react';

import { viewDropStyles } from './ViewDrop.styles';
import type { Props } from './ViewDrop.types';
import { ViewDropModule } from './ViewDropNativeModule';
import { Platform } from 'react-native';

export const ViewDrop: FC<Props> = ({
  children,
  onImageReceived,
  onDropItemDetected,
  onVideoReceived,
  ...props
}) => {
  const onImageReceivedEvent = (event: SyntheticEvent) => {
    if (!onImageReceived) {
      return;
    }
    //@ts-ignore
    const image = event.nativeEvent?.image;
    onImageReceived(image);
  };

  const onVideoReceivedEvent = (event: SyntheticEvent) => {
    if (!onVideoReceived) {
      return;
    }
    //@ts-ignore
    const videoInfo = event.nativeEvent?.videoInfo;
    onVideoReceived(videoInfo);
  };

  const onDropItemDetectedEvent = () => {
    if (!onDropItemDetected) {
      return;
    }

    onDropItemDetected();
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
    >
      {children}
    </ViewDropModule>
  );
};
