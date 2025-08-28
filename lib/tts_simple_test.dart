import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TTS Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TtsTestPage(),
    );
  }
}

class TtsTestPage extends StatefulWidget {
  const TtsTestPage({Key? key}) : super(key: key);

  @override
  State<TtsTestPage> createState() => _TtsTestPageState();
}

class _TtsTestPageState extends State<TtsTestPage> {
  final FlutterTts flutterTts = FlutterTts();
  String text = "Hello, this is a test of the text to speech functionality.";
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
      });
    });
  }

  Future<void> speak() async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
      setState(() {
        isPlaying = true;
      });
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter TTS Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(text, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isPlaying ? stop : speak,
              child: Text(isPlaying ? 'Stop' : 'Speak'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}