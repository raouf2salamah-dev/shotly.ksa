# Security CI/CD Pipeline Documentation

## Overview

This document describes the security-focused CI/CD pipeline implemented for the Flutter application. The pipeline is designed to automatically detect security vulnerabilities, enforce secure coding practices, and validate security features during the development process.

## Pipeline Components

### 1. Static Analysis

- **Tool**: Flutter Analyze with enhanced security rules
- **Configuration**: `analysis_options.yaml`
- **Purpose**: Identifies potential security issues in code, including:
  - Hardcoded credentials
  - Insecure coding patterns
  - Potential vulnerabilities
  - Code quality issues that could lead to security problems

### 2. Dependency Vulnerability Scanning

- **Tools**: 
  - Snyk
  - OWASP Dependency-Check
- **Configuration**: 
  - `dependency-check-config.json`
  - `dependency-suppressions.xml`
- **Purpose**: Identifies known vulnerabilities in third-party dependencies

### 3. SSL Pinning Verification

- **Tool**: Custom CI certificate pinning test script
- **Script**: `ci_certificate_pinning_test.sh`
- **Purpose**: Validates that SSL certificate pinning is correctly implemented
- **Output**: JSON and HTML reports with timestamp and certificate hash

### 4. SonarQube Analysis

- **Tool**: SonarQube
- **Configuration**: `sonar-project.properties`
- **Purpose**: Comprehensive code quality and security analysis

### 5. Test Coverage and Reporting

- **Tools**: 
  - Flutter Test with coverage
  - LCOV report generator
- **Scripts**:
  - `generate_test_reports.sh`
- **Purpose**: Generates and merges test coverage reports from Flutter tests and security tests
- **Output**: HTML and JSON reports, LCOV coverage data

## How to Run Locally

To run the security checks locally before committing code:

```bash
# Run static analysis
flutter analyze

# Generate analyzer report
./scripts/generate_analyzer_report.sh

# Run SSL pinning test
cd test_scripts
./ci_certificate_pinning_test.sh

# Run Flutter tests with coverage
flutter test --coverage

# Generate and merge test reports
cd test_scripts
./generate_test_reports.sh

# Run dependency checks (requires OWASP Dependency-Check installation)
dependency-check --project "Flutter Security App" --scan . --out reports
```

## Test Reports

### Report Formats

The pipeline generates test reports in multiple formats:

- **JSON**: Machine-readable test results
- **HTML**: Human-readable test reports with visual formatting
- **LCOV**: Code coverage data that can be used by various tools

### Report Contents

- **SSL Pinning Tests**: Pass/fail status, timestamp, certificate hash
- **Flutter Tests**: Code coverage metrics
- **Static Analysis**: Linting and code quality issues
- **Dependency Checks**: Vulnerability reports

### Report Storage and Access

Test reports are stored and made accessible through multiple channels:

1. **GitHub Actions Artifacts**: All reports are uploaded as artifacts in the workflow run
2. **GitHub Pages**: Reports are published to GitHub Pages when commits are made to main/master branches
3. **Firebase Hosting** (optional): Reports can be uploaded to Firebase Hosting if configured
4. **AWS S3** (optional): Reports can be stored in an S3 bucket if configured

## Maintaining the Pipeline

### Adding New Security Checks

1. Create a new test script in the `test_scripts` directory
2. Update the GitHub Actions workflow file (`.github/workflows/security_pipeline.yml`)
3. Document the new check in this file

### Updating Security Rules

1. Modify the `analysis_options.yaml` file to add or update linting rules
2. Update the SonarQube configuration in `sonar-project.properties` if needed

### Managing False Positives

1. For dependency vulnerabilities, update the `dependency-suppressions.xml` file
2. For SonarQube false positives, add exclusions in `sonar-project.properties`

## Required Secrets

The following secrets need to be configured in your GitHub repository:

### Required for Core Pipeline

- `SNYK_TOKEN`: API token for Snyk vulnerability scanning
- `SONAR_TOKEN`: Authentication token for SonarQube
- `SONAR_HOST_URL`: URL of your SonarQube instance

### Optional for Report Uploading

- `FIREBASE_PROJECT_ID`: Firebase project ID for hosting reports
- `FIREBASE_TOKEN`: Firebase authentication token
- `AWS_ACCESS_KEY_ID`: AWS access key for S3 uploads
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for S3 uploads
- `AWS_REGION`: AWS region for S3 bucket
- `AWS_S3_BUCKET`: S3 bucket name for storing reports

## Failure Conditions

The pipeline will fail under the following conditions:

1. Static analysis errors
2. Critical vulnerabilities (CVSS score ≥ 7) in dependencies
3. SSL pinning verification failure
4. SonarQube quality gate failure

## Troubleshooting

### Common Issues

1. **SSL Pinning Test Failures**
   - Verify that the expected certificate fingerprint in `ci_certificate_pinning_test.sh` matches your current API endpoint
   - Check that the certificate fingerprint is correctly implemented in the code
   - Review the JSON/HTML reports for detailed error information

2. **Dependency Check Failures**
   - Review the vulnerability report in the GitHub Actions artifacts
   - Update dependencies to secure versions or add justified suppressions

3. **SonarQube Integration Issues**
   - Verify that the analyzer report is being generated correctly
   - Check that the SonarQube configuration matches your instance settings

4. **Test Report Generation Issues**
   - Ensure the reports directory exists and is writable
   - Check that the LCOV file is being generated correctly by Flutter tests
   - Verify that the `generate_test_reports.sh` script has executable permissions

5. **Report Upload Failures**
   - For GitHub Pages: Verify that the workflow has correct permissions to push to the gh-pages branch
   - For Firebase: Check that the Firebase project ID and token are correctly configured
   - For AWS S3: Ensure that the AWS credentials have permission to write to the specified bucket