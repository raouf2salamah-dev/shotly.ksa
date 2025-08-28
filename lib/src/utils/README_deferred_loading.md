# Deferred Loading Utilities

## DeferredLoader

The `DeferredLoader` class provides a simple and efficient way to manage deferred loading of libraries in Flutter applications. It ensures that each library is loaded only once, even when called concurrently from multiple places in your code.

### Key Features

- **Concurrent Loading Protection**: Prevents multiple simultaneous loading attempts of the same library
- **Loading Status Tracking**: Provides status information about whether a library is loaded
- **Timeout Support**: Optional timeout parameter to prevent indefinite waiting
- **Simple API**: Easy to use with any deferred library

### Usage

1. First, import your library with the `deferred as` keyword:

```dart
import 'package:some_package/some_package.dart' deferred as some_package;
```

2. Create a `DeferredLoader` instance for the library:

```dart
final _packageLoader = DeferredLoader(some_package.loadLibrary);
```

3. Use the loader to ensure the library is loaded before using it:

```dart
await _packageLoader.ensureLoaded();
// Now you can use some_package
some_package.someFunction();
```

### Example with Image Picker

```dart
import 'package:image_picker/image_picker.dart' deferred as image_picker;
import '../utils/deferred_loader.dart';

class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> {
  final _imagePickerLoader = DeferredLoader(image_picker.loadLibrary);
  
  Future<void> _pickImage() async {
    // Ensure the library is loaded
    await _imagePickerLoader.ensureLoaded();
    
    // Now we can use the image_picker
    final pickedFile = await image_picker.ImagePicker().pickImage(
      source: image_picker.ImageSource.gallery,
    );
    
    // Process the picked image
    // ...
  }
}
```

### Benefits of Using DeferredLoader

1. **Reduced Initial Load Time**: Libraries are loaded only when needed
2. **Lower Memory Footprint**: Resources are allocated only when required
3. **Improved Performance**: App starts faster and runs more efficiently
4. **Better User Experience**: Smoother app startup and operation

### Best Practices

- Use deferred loading for heavy libraries that aren't needed immediately
- Consider using deferred loading for features used by only a subset of users
- Good candidates include: image/file pickers, video players, PDF viewers, etc.
- Add appropriate loading indicators when waiting for libraries to load
- Handle errors gracefully in case loading fails

### Example Files

Check out these example implementations in the codebase:

- `image_picker_deferred_example.dart`
- `file_picker_deferred_example.dart`
- `video_player_deferred_example.dart`