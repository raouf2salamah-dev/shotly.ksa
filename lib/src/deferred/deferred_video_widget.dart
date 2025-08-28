import 'package:flutter/widgets.dart'; 
import 'package:video_player/video_player.dart' as vplayer; 

/// Use only after the library is loaded and controller initialized 
class DeferredVideoWidget extends StatelessWidget { 
  final vplayer.VideoPlayerController controller; 
  const DeferredVideoWidget({super.key, required this.controller}); 

  @override 
  Widget build(BuildContext context) { 
    return vplayer.VideoPlayer(controller); 
  } 
}