import { type SyntheticEvent } from 'react';
import { type ViewProps } from 'react-native';

export interface ViewDropNativeModuleProps {
  onImageReceived: (event: SyntheticEvent) => void;
  onDropItemDetected: (event: SyntheticEvent) => void;
  onVideoReceived: (event: SyntheticEvent) => void;
  onAudioReceived: (event: SyntheticEvent) => void;
}

export type AvAssetType = {
  fullUrl: string;
  fileName: string;
};

export type Props = {
  onImageReceived?: (image: string) => void;
  onDropItemDetected?: () => void;
  onVideoReceived?: (videoInfo: AvAssetType) => void;
  onAudioReceived?: (audioInfo: AvAssetType) => void;
} & ViewProps;
