

import { type SyntheticEvent } from 'react';
import { type ViewProps } from 'react-native';

export interface ViewDropNativeModuleProps {
    onImageReceived: (event: SyntheticEvent) => void;
}

export type Props = {
    onImageReceived?: (image: string) => void;
} & ViewProps;
