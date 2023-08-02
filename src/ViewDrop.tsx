

import React, { type FC, type SyntheticEvent } from 'react';

import { viewDropStyles } from './ViewDrop.styles';
import type { Props } from './ViewDrop.types';
import { ViewDropModule } from './ViewDropNativeModule';
import { Platform } from 'react-native';

export const ViewDrop: FC<Props> = ({
  children,
  onImageReceived,
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

  if (Platform.OS === 'android') {
    return <>{children}</>;
  }

  return (
    <ViewDropModule
      style={viewDropStyles.viewDrop}
      {...props}
      onImageReceived={onImageReceivedEvent}
    >
      {children}
    </ViewDropModule>
  );
};
