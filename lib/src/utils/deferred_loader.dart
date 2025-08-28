import 'dart:async'; 
 
/// Simple guard so each library loads once even if called concurrently. 
class DeferredLoader { 
  bool _loading = false; 
  bool _loaded = false; 
  final Future<void> Function() _loadFn; 
  DeferredLoader(this._loadFn); 

  Future<void> ensureLoaded({Duration? timeout}) async { 
    if (_loaded) return; 
    if (_loading) { 
      // Wait until first load finishes 
      while (_loading) { 
        await Future<void>.delayed(const Duration(milliseconds: 20)); 
      } 
      return; 
    } 
    _loading = true; 
    try { 
      final future = _loadFn(); 
      if (timeout != null) { 
        await future.timeout(timeout); 
      } else { 
        await future; 
      } 
      _loaded = true; 
    } finally { 
      _loading = false; 
    } 
  } 

  bool get isLoaded => _loaded; 
}