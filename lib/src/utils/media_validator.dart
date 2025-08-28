import 'dart:io'; 
import 'package:image/image.dart' as img; 

/// Optional moderation dependency (people/animals) 
typedef DetectPeopleOrAnimals = Future<bool> Function(File image); 

class MediaValidator { 
  // Limits 
  static const int maxImageSizeMB = 2; 
  static const int maxVideoSizeMB = 15; 
  static const int maxImageEdge = 1920; // longest side 
  static const Duration maxVideoDuration = Duration(minutes: 1); 

  final DetectPeopleOrAnimals? detectPeopleOrAnimals; 

  MediaValidator({this.detectPeopleOrAnimals}); 

  Future<String?> validateImage(File file) async { 
    // size 
    final sizeMB = file.lengthSync() / (1024 * 1024); 
    if (sizeMB > maxImageSizeMB) { 
      return "Image must be under $maxImageSizeMB MB."; 
    } 

    // resolution 
    final decoded = img.decodeImage(file.readAsBytesSync()); 
    if (decoded != null) { 
      final longest = decoded.width > decoded.height ? decoded.width : decoded.height; 
      if (longest > maxImageEdge) { 
        return "Image resolution too high. Max $maxImageEdge px on longest side."; 
      } 
    } 

    // moderation (optional, low-cost toggle) 
    if (detectPeopleOrAnimals != null) { 
      final hasPeopleOrAnimals = await detectPeopleOrAnimals!(file); 
      if (hasPeopleOrAnimals) { 
        return "Images containing people or animals are not allowed."; 
      } 
    } 

    return null; // OK 
  } 

  Future<String?> validateVideo({ 
    required Duration duration, 
    required int fileBytesLength, 
  }) async { 
    final sizeMB = fileBytesLength / (1024 * 1024); 
    if (sizeMB > maxVideoSizeMB) { 
      return "Video must be under $maxVideoSizeMB MB."; 
    } 
    if (duration > maxVideoDuration) { 
      return "Video cannot be longer than ${maxVideoDuration.inMinutes} minute."; 
    } 
    return null; // OK 
  } 
}