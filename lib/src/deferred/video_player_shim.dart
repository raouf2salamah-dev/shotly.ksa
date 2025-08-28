import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart' as vplayer;
import 'deferred_video_widget.dart';

/// A compatibility layer for video player components
/// 
/// This file provides a unified interface for video player components
/// regardless of whether they're loaded directly or via deferred loading.
/// 
/// Usage:
/// ```dart
/// import 'deferred/video_player_shim.dart';
/// // ...
/// DeferredVideoWidget(controller: controller);
/// ```
export 'deferred_video_widget.dart';