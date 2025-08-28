import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_page_transitions.dart';
import '../../utils/deep_link_handler.dart';

/// A demo screen to showcase different page transition animations
class TransitionsDemoScreen extends StatefulWidget {
  final String? transitionType;
  
  const TransitionsDemoScreen({Key? key, this.transitionType}) : super(key: key);

  @override
  State<TransitionsDemoScreen> createState() => _TransitionsDemoScreenState();
}

class _TransitionsDemoScreenState extends State<TransitionsDemoScreen> {
  int _currentIndex = 0;
  String _transitionType = 'custom';
  
  final List<Widget> _pages = [
    const _DemoPage(
      color: Colors.blue,
      title: 'Page 1',
      description: 'This is the first page with a fade transition',
    ),
    const _DemoPage(
      color: Colors.green,
      title: 'Page 2',
      description: 'This is the second page with a slide transition',
    ),
    const _DemoPage(
      color: Colors.orange,
      title: 'Page 3',
      description: 'This is the third page with a custom transition',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.transitionType != null) {
      _transitionType = widget.transitionType!;
    }
  }
  
  Widget _buildTransition() {
    switch (_transitionType) {
      case 'fade':
        return FadePageTransition(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        );
      case 'slide':
        return SlidePageTransition(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        );
      case 'custom':
      default:
        return CustomPageTransition(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transitions Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildTransition(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                          });
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < _pages.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showTransitionSelector(context);
                  },
                  child: const Text('Try Different Transitions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Transitions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This demo showcases different page transition animations using AnimatedSwitcher.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'These transitions can be used throughout the app for smoother navigation between screens.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Try the different transition types using the button below.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _testDeepLink() async {
    final deepLinkHandler = DeepLinkHandler();
    final uri = deepLinkHandler.generateTransitionsLink(_transitionType);
    
    // Show a snackbar with the deep link information
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing deep link: ${uri.toString()}'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: uri.toString()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deep link copied to clipboard')),
            );
          },
        ),
      ),
    );
    
    // Simulate opening the app with this deep link
    Future.delayed(const Duration(seconds: 1), () {
      // This simulates what would happen if the app received this URI from outside
      final result = deepLinkHandler.handleUri(uri);
      if (result != null) {
        context.go(result);
      }
    });
  }

  void _showTransitionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Transition Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.opacity),
              title: const Text('Fade Transition'),
              selected: _transitionType == 'fade',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _transitionType = 'fade';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.slideshow),
              title: const Text('Slide Transition'),
              selected: _transitionType == 'slide',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _transitionType = 'slide';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.animation),
              title: const Text('Custom Transition'),
              selected: _transitionType == 'custom',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _transitionType = 'custom';
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _testDeepLink();
              },
              child: const Text('Test Deep Link Navigation'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTransitionExample(String type) {
    context.go('/transitions-example/$type');
  }
}

class _DemoPage extends StatelessWidget {
  final Color color;
  final String title;
  final String description;

  const _DemoPage({
    Key? key,
    required this.color,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.swipe,
                  size: 48,
                  color: Colors.black54,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Swipe or use buttons to navigate',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}