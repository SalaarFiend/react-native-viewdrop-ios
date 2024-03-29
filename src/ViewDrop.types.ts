import { type SyntheticEvent } from 'react';
import { type ViewProps } from 'react-native';

export interface ViewDropNativeModuleProps {
  onImageReceived: (event: SyntheticEvent) => void;
  onDropItemDetected: (event: SyntheticEvent) => void;
}

export type Props = {
  onImageReceived?: (image: string) => void;
  onDropItemDetected?: () => void;
} & ViewProps;
