# Shotly

A mobile-first platform that enables seamless peer-to-peer transactions of original digital content (photos, videos, GIFs) by transforming smartphones into self-contained creative commerce tools.

## Overview

This platform caters to both casual users and professional content creators, offering monetization, discovery, and intuitive content management. Built with FlutterFlow and Firebase, it provides a complete ecosystem for digital content commerce.

## User Roles & Capabilities

### Seller (Content Creator)
- Create an account via secure authentication
- Upload media (photo, video, GIF) directly from device gallery or camera
- Add metadata: title, description, pricing
- Organize and edit content (edit/delete options)
- Access analytics dashboard: views, sales, revenue
- Withdraw earnings via integrated payout system
- Use AI-powered assistant for product descriptions and marketing content

### Buyer (Content Consumer)
- Browse curated, visual-first marketplace
- Use filters (media type, category, price) and search bar for discovery
- Preview media before purchase
- Favorite media for future reference
- Purchase and download media for personal or commercial use

## Platform Features

- **Media Upload Engine**: Drag-and-drop or tap-to-upload interface with automatic preview generation
- **Revenue Engine**: Payment integration to facilitate purchases; automatic earnings logging per seller
- **Marketplace UI**: Clean, minimal, and visually prioritized interface optimized for both quick browsing and deep search
- **User Authentication**: Firebase Auth for secure login/sign-up workflows (email, OAuth)
- **Cloud Storage**: Firebase Storage used for all user-generated content; linked to Firestore records
- **Contextual UI**: Role-differentiated dashboards and navigation menus
- **Search & Discoverability**: Full-text and tag-based search, with filters (type, category, popularity, price)
- **Seller Dashboard**: Real-time stats (views, downloads, revenue, top-performing media)
- **AI Capabilities**: 
  - Smart tagging, auto-categorization, and relevance-based sorting
  - AI Seller Assistant for generating product descriptions and marketing content
  - Response caching system for improved performance and reduced API costs

## Tech Stack

- **Frontend**: FlutterFlow (for iOS/Android/Web with single codebase)
- **Backend & Services**:
  - Firebase Authentication: Secure and scalable user auth
  - Firebase Firestore: Real-time NoSQL database for user and media records
  - Firebase Storage: Media asset management
  - Firebase Hosting: Web access (if needed)
  - Firestore Security Rules: Secure access control for database collections

## Security Features

- **Secure Storage**: Flutter Secure Storage for sensitive user data and settings
- **Code Obfuscation**: Release builds use Flutter's obfuscation to protect intellectual property
- **Debug Info Splitting**: Debug symbols separated from release builds for smaller, more secure distribution
- **Android Security**: ProGuard/R8 enabled for code shrinking and obfuscation
- **iOS Security**: Appropriate build settings for secure deployment
- **Sensitive UI Protection**: Secure screens prevent screenshots and app switcher previews of sensitive content
  - AI Stack (Optional): Integration-ready slots for model inference

## Security CI/CD Pipeline

The application includes a comprehensive security-focused CI/CD pipeline that automatically runs on every push and pull request:

- **Static Analysis**: Flutter analyze with enhanced security rules to detect potential vulnerabilities
- **Dependency Scanning**: Snyk and OWASP Dependency-Check to identify vulnerabilities in third-party packages
- **SSL Pinning Verification**: Automated tests to ensure certificate pinning is correctly implemented, with JSON/HTML reports
- **SonarQube Analysis**: Code quality and security scanning with customized rules
- **Test Coverage**: Flutter test coverage reports merged with security test results
- **Centralized Reporting**: Test results uploaded to GitHub Pages, Firebase Hosting, or AWS S3

See [Security Pipeline Documentation](docs/security_pipeline.md) for details on setup and maintenance.

## Use Cases

- Photographers monetizing original imagery
- Videographers sharing artistic or viral clips
- Digital artists distributing looped GIFs
- Agencies and businesses sourcing niche, authentic content
- Social users turning everyday moments into passive income

## Future Expansion

- In-app messaging or negotiation between buyers and sellers
- Tiered subscriptions, bundle pricing models
- AI recommendation engine (for both buyers and sellers)
- Tokenized ownership via NFT/blockchain architecture (modular plugin)
- Advanced licensing options for different usage rights