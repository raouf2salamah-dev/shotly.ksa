import 'dart:io';
import 'package:flutter/foundation.dart';
import '../deferred/image_picker_wrapper.dart';
import '../deferred/file_picker_wrapper.dart';
import '../deferred/video_player_helper.dart';
import '../utils/media_validator.dart';

class UploadResult {
  final File? file;
  final String? error;
  const UploadResult.success(this.file) : error = null;
  const UploadResult.error(this.error) : file = null;
  bool get isSuccess => file != null;
}

class UploadFlowService {
  final MediaValidator _validator;
  UploadFlowService(this._validator);

  /// Picks image (gallery), validates, returns file or error.
  Future<UploadResult> pickAndValidateImage() async {
    final file = await DeferredImagePicker.pickImageFromGallery(imageQuality: 85);
    if (file == null) return const UploadResult.error("No image selected.");

    final err = await _validator.validateImage(file);
    if (err != null) return UploadResult.error(err);

    return UploadResult.success(file);
  }

  /// Picks video (mp4/mov), validates length<=1min + size, returns file or error.
  Future<UploadResult> pickAndValidateVideo() async {
    final file = await DeferredFilePicker.pickSingleFile(
      allowedExtensions: ['mp4', 'mov'],
    );
    if (file == null) return const UploadResult.error("No video selected.");

    // Probe duration via deferred video controller (no playback)
    final helper = DeferredVideoController();
    try {
      final ok = await helper.initializeFromFile(file);
      if (!ok) return const UploadResult.error("Failed to load video metadata.");
      final duration = helper.rawController!.value.duration;
      final bytes = file.lengthSync();

      final err = await _validator.validateVideo(
        duration: duration,
        fileBytesLength: bytes,
      );
      if (err != null) return UploadResult.error(err);
      return UploadResult.success(file);
    } catch (e) {
      debugPrint("Video validate error: $e");
      return const UploadResult.error("Unable to validate video.");
    } finally {
      helper.dispose();
    }
  }
}