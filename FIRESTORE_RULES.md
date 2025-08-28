# Firestore Security Rules

This document describes the security rules implemented for the Shotly application's Firestore database.

## Overview

The security rules in `firestore.rules` control access to the Firestore collections based on user authentication status and roles. These rules follow the principle of least privilege, denying access by default and only granting specific permissions where needed.

## Collections and Access Rules

### Default Rule

By default, all access to the database is denied:

```
match /{document=**} {
  allow read, write: if false;
}
```

### AI Cache Collection

The `ai_cache` collection stores temporary data for AI processing features, including cached responses from AI services to improve performance and reduce API costs:

```
match /ai_cache/{docId} {
  allow read, write: if request.auth != null;
}
```

- **Read/Write Access**: Any authenticated user
- **Usage**: Used by the `AIService` class to cache AI responses based on prompts, reducing duplicate API calls to external AI providers

### Users Collection

The `users` collection stores user profile information:

```
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
  allow update: if request.auth != null && (request.auth.uid == userId || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin" || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true);
}
```

- **Read Access**: Any authenticated user
- **Write Access**: Only the user themselves
- **Update Access**: The user themselves, admins, or super admins

### Content Collection

The `content` collection stores digital content items:

```
match /content/{contentId} {
  allow read: if true; // Public read access
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null && 
    (request.resource.data.sellerId == request.auth.uid || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin" || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true);
}
```

- **Read Access**: Public (anyone can view content)
- **Create Access**: Any authenticated user
- **Update/Delete Access**: The content seller, admins, or super admins

### Transactions Collection

The `transactions` collection records purchase transactions:

```
match /transactions/{transactionId} {
  allow read: if request.auth != null && 
    (resource.data.buyerId == request.auth.uid || 
    resource.data.sellerId == request.auth.uid || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin" || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true);
  allow create: if request.auth != null;
  allow update: if false; // Transactions should be immutable
  allow delete: if false; // Transactions should not be deleted
}
```

- **Read Access**: The buyer, seller, admins, or super admins
- **Create Access**: Any authenticated user
- **Update/Delete Access**: Denied (transactions are immutable)

### Metadata Collection

The `metadata` collection stores application-wide settings and data:

```
match /metadata/{docId} {
  allow read: if true; // Public read access
  allow write: if request.auth != null && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin" || 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true);
}
```

- **Read Access**: Public (anyone can read metadata)
- **Write Access**: Admins or super admins only

## Deployment

To deploy these rules to your Firebase project, use the Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

## Security Considerations

1. These rules enforce role-based access control (RBAC)
2. Transactions are immutable to maintain financial integrity
3. Content is publicly readable but protected from unauthorized modifications
4. User data is protected from unauthorized access
5. Administrative functions are restricted to users with appropriate roles

## Testing

It's recommended to test these rules using the Firebase Emulator Suite before deployment to production.

## Implementation Details

### AIService Implementation

The `AIService` class implements a caching mechanism using the `ai_cache` collection to optimize AI response retrieval and reduce API costs. The implementation requires the following imports:

```dart
import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:cloud_firestore/cloud_firestore.dart';
```

The service is used by the `SellerAIAssistant` widget to provide AI-powered assistance to sellers:

```dart
class AIService { 
  final _db = FirebaseFirestore.instance; 

  Future<String> getAIResponse(String prompt) async { 
    // 1️⃣ Check cache 
    var cached = await _db 
        .collection('ai_cache') 
        .where('prompt', isEqualTo: prompt) 
        .get(); 

    if (cached.docs.isNotEmpty) { 
      print("💾 Using cached response"); 
      return cached.docs.first['response']; 
    } 

    // 2️⃣ API request (OpenAI example) 
    var url = Uri.parse("https://api.openai.com/v1/chat/completions"); 
    var headers = { 
      "Content-Type": "application/json", 
      "Authorization": "Bearer YOUR_OPENAI_KEY" // replace with your free-tier key 
    }; 

    var body = jsonEncode({ 
      "model": "gpt-3.5-turbo", 
      "messages": [ 
        {"role": "system", "content": "You are an AI sales assistant."}, 
        {"role": "user", "content": prompt} 
      ], 
      "max_tokens": 200 
    }); 

    var response = await http.post(url, headers: headers, body: body); 
    if (response.statusCode == 200) { 
      var reply = jsonDecode(response.body)['choices'][0]['message']['content']; 

      // 3️⃣ Save to cache 
      await _db.collection('ai_cache').add({ 
        "prompt": prompt, 
        "response": reply, 
        "timestamp": DateTime.now() 
      }); 

      return reply; 
    } else { 
      throw Exception("AI request failed: ${response.body}"); 
    } 
  } 
}
```

This implementation:
1. First checks if a response for the given prompt exists in the cache
2. If found, returns the cached response immediately
3. If not found, makes an API request to an external AI service (OpenAI in this example)
4. Saves the new response to the cache for future use
5. Returns the response to the caller

### Security Considerations for AI Integration

1. **API Key Security**: The OpenAI API key should never be hardcoded in the application. Instead, use secure methods like:
   - Firebase Remote Config
   - Environment variables on the server side
   - Firebase Functions for proxying requests

2. **Cache Expiration**: Consider adding a timestamp-based expiration mechanism to the cache entries

3. **Rate Limiting**: Implement rate limiting to prevent abuse of the AI service

4. **Content Filtering**: Apply appropriate content filtering for user prompts and AI responses

### SellerAIAssistant Widget Implementation

The `SellerAIAssistant` widget provides a user interface for sellers to interact with the AI service:

```dart
class SellerAIAssistant extends StatefulWidget {
  const SellerAIAssistant({Key? key}) : super(key: key);

  @override
  State<SellerAIAssistant> createState() => _SellerAIAssistantState();
}

class _SellerAIAssistantState extends State<SellerAIAssistant> {
  final _aiService = AIService();
  final _controller = TextEditingController();
  String _result = "";
  bool _loading = false;

  _runAI() async {
    setState(() => _loading = true);
    var reply = await _aiService.getAIResponse(_controller.text);
    setState(() {
      _result = reply;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI implementation
  }
}
```

This widget:
1. Creates an instance of the `AIService`
2. Provides a text input for the seller to enter their prompt
3. Displays a loading indicator while waiting for the AI response
4. Shows the AI-generated response in a scrollable text area
5. Leverages the Firestore caching mechanism through the `AIService`