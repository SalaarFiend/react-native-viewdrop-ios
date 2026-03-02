# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
# Initial setup (install all dependencies and CocoaPods)
yarn bootstrap

# Run example app
yarn example start        # start Metro bundler
yarn example ios          # run on iOS simulator
yarn example android      # run on Android

# Quality checks
yarn typecheck            # TypeScript type checking
yarn lint                 # ESLint
yarn lint --fix           # auto-fix lint errors
yarn test                 # run Jest tests

# Build the library (outputs to lib/)
yarn prepack              # runs react-native-builder-bob

# Release
yarn release              # bump version, create tag, publish to npm
```

To edit native iOS code in Xcode, open `example/ios/ViewdropIosExample.xcworkspace`. The library source files appear under `Pods > Development Pods > react-native-viewdrop-ios`.

### Testing with New Architecture

```sh
cd example/ios && RCT_NEW_ARCH_ENABLED=1 pod install && cd ../.. && yarn example ios
```

For Old Architecture (default):

```sh
cd example/ios && pod install && cd ../.. && yarn example ios
```

## Architecture

This is a React Native library built with [react-native-builder-bob](https://github.com/callstack/react-native-builder-bob). It wraps a native iOS `UIDropInteraction`-based view so React Native components can receive drag-and-drop payloads (images, videos).

**The library is iOS-only.** On Android, `ViewDrop` renders a transparent passthrough (`<>{children}</>`).

**Requires React Native >= 0.71.0** (uses `codegenNativeComponent` and codegen types).

**Supports both Old Architecture and New Architecture (Fabric).**

### Layer breakdown

| Layer | Files | Role |
|---|---|---|
| Public API | `src/index.tsx` | Re-exports `ViewDrop` |
| React component | `src/ViewDrop.tsx` | Unwraps native events, guards Android |
| Native bridge types | `src/ViewDrop.types.ts` | Props interfaces |
| Codegen spec | `src/ViewDropNativeComponent.ts` | `codegenNativeComponent('ViewDropModule')` — falls back to `requireNativeComponent` on Old Arch |
| Swift view manager (Old Arch) | `ios/VIewDropModule.swift` | `RCTViewManager` subclass, instantiates `ViewDrop` |
| ObjC bridge (Old Arch) | `ios/ViewDropManager.m` | `RCT_EXTERN_MODULE` exposing event and config props |
| Fabric component view (New Arch) | `ios/ViewDropComponentView.mm` | `RCTViewComponentView` subclass, guarded by `#ifdef RCT_NEW_ARCH_ENABLED` |
| Swift view | `ios/ViewDrop.swift` | `UIView` + `UIDropInteractionDelegate`; converts drops to base64 images or temp-file video URLs |
| Image scaling | `ios/ImageScaleExtension.swift` | `UIImage` extension; downscales images larger than 6048×4032 |
| Android no-op | `android/.../ViewDropModuleManager.kt` | Minimal `SimpleViewManager` for codegen compatibility |

### New Architecture specifics

- `ViewDropComponentView.mm` uses `NSClassFromString(@"ViewDrop")` + KVC to avoid compile-time dependency on the Swift-generated header (Swift headers are unavailable in ObjC++ pods during CocoaPods builds)
- UIDropInteraction is moved from `_viewDrop` to `self` (the component view) so drag sessions work while React children still receive touch events
- `onFileItemsReceived` sends data as a JSON string (codegen for RN 0.72 does not support `ReadonlyArray` in events); the JS wrapper parses it back to `Record<MapKeysMultiItems, FileInfo[]>`
- The `codegenConfig` in `package.json` defines the spec name `ViewdropIosSpec`

### Native event flow

1. User drags an item over `ViewDrop` → `dropInteraction(_:sessionDidEnter:)` fires → emits `onDropItemDetected`.
2. User releases → `dropInteraction(_:performDrop:)` fires:
   - **Image**: loaded as `UIImage`, optionally downscaled, encoded as base64 PNG (with alpha) or JPEG, emitted on `onImageReceived` as `{ image: "data:image/...;base64,..." }`.
   - **Video**: raw data written to `NSTemporaryDirectory()` as a `.mov` file, emitted on `onVideoReceived` as `{ videoInfo: { fileName, fullUrl } }`.
   - **Multi-drop**: files grouped by type, serialized as JSON string, emitted on `onFileItemsReceived` as `{ data: "<json>" }`.
3. The React component (`src/ViewDrop.tsx`) unwraps `event.nativeEvent` and calls the user-supplied callback.

### Build output

`react-native-builder-bob` compiles `src/` into `lib/` with three targets: CommonJS, ES module, and TypeScript declarations. Run `yarn prepack` to rebuild after changing source.

## Commit convention

Follows [Conventional Commits](https://www.conventionalcommits.org/): `fix:`, `feat:`, `refactor:`, `docs:`, `test:`, `chore:`. Pre-commit hooks (lefthook) enforce this and run linter + tests.
