# Security Dashboard

A Flutter web dashboard that provides visibility into your application's security features, CI/CD pipeline, and test history.

## Features

### Security Features Status
- Displays active/inactive status of all security features
- Detailed view for each security feature showing:
  - Implementation details
  - Last updated timestamp
  - Protected domains (for SSL pinning)
  - Configuration information

### CI/CD Build Metadata
- Latest build information
- Build number and timestamp
- Branch and commit details
- Build status with color coding
- Build duration

### Test History
- Visual chart of test pass/fail history
- Detailed table of recent test results
- Total, passed, and failed test counts

### Automatic Updates
- Webhook integration with CI/CD pipeline
- Real-time dashboard updates after each build
- Last update timestamp display

## Running the Dashboard

### Local Development

```bash
# Run the dashboard locally
./run_dashboard.sh
```

This will start the dashboard on http://localhost:8080

### Deployment

The dashboard can be deployed to:
- GitHub Pages
- Firebase Hosting
- AWS S3

Deployment is handled automatically by the CI/CD pipeline for main/master branch builds.

## Architecture

### Components

- **DashboardWebApp**: Main entry point for the web application
- **DashboardHome**: Container for the dashboard with navigation
- **SecurityDashboard**: Main dashboard view with all panels
- **WebhookService**: Handles CI/CD webhook integration
- **BuildMetadataService**: Fetches build information
- **SecurityFeaturesService**: Checks security feature status
- **TestHistoryChart**: Visualizes test history

### Integration

The dashboard integrates with your CI/CD pipeline through:

1. **Webhook Endpoint**: Receives build notifications
2. **API Services**: Fetches security status and build metadata
3. **Report Storage**: Accesses test reports from GitHub Pages/Firebase/AWS S3

## Configuration

The dashboard can be configured by modifying the following files:

- **webhook_service.dart**: Configure webhook endpoint and authentication
- **build_metadata_service.dart**: Configure API endpoints for build data
- **security_features_service.dart**: Configure security feature checks

## Development

To extend the dashboard:

1. Add new panels to the SecurityDashboard class
2. Create new service classes for additional data sources
3. Extend the webhook payload processing for new event types