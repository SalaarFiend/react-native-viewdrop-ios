import { type ViewProps, requireNativeComponent } from 'react-native';

import { type ViewDropNativeModuleProps } from './ViewDrop.types';

export const ViewDropModule = requireNativeComponent<
  ViewProps & ViewDropNativeModuleProps
>('ViewDropModule');
