import 'dart:ffi' as ffi;
import 'package:flutter/foundation.dart';

typedef _PatchNumNative = ffi.UintPtr Function();
typedef _PatchNumDart = int Function();

/// Checks Shorebird's engine symbols in `libflutter.so` to detect if a new
/// over-the-air patch has finished downloading in the background for next boot.
/// Uses `providesSymbol` first so it never throws an exception in the debugger.
bool isNewShorebirdPatchDownloaded() {
  if (!kReleaseMode) return false;
  try {
    final lib = ffi.DynamicLibrary.process();
    if (!lib.providesSymbol('shorebird_current_boot_patch_number') ||
        !lib.providesSymbol('shorebird_next_boot_patch_number')) {
      return false;
    }
    final currentFn = lib
        .lookup<ffi.NativeFunction<_PatchNumNative>>(
          'shorebird_current_boot_patch_number',
        )
        .asFunction<_PatchNumDart>();
    final nextFn = lib
        .lookup<ffi.NativeFunction<_PatchNumNative>>(
          'shorebird_next_boot_patch_number',
        )
        .asFunction<_PatchNumDart>();

    final currentPatch = currentFn();
    final nextPatch = nextFn();
    return nextPatch > 0 && nextPatch != currentPatch;
  } catch (_) {
    return false;
  }
}
