// This is a basic Flutter widget test for Civic Connect app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_connect_app/constants/app_constants.dart';
import 'package:civic_connect_app/constants/app_theme.dart';

void main() {
  group('Civic Connect App Tests', () {
    test('App constants are correct', () {
      // Test app constants without widget testing
      expect(AppConstants.appName, equals('Civic Connect'));
      expect(AppConstants.appVersion, equals('1.0.0'));
      expect(AppConstants.appTagline, equals('Your Voice, Our Action'));
    });

    test('Issue categories are properly defined', () {
      // Test that issue categories are properly defined
      expect(AppConstants.issueCategories, isNotEmpty);
      expect(AppConstants.issueCategories.length, greaterThan(0));
      
      // Check first category structure
      final firstCategory = AppConstants.issueCategories.first;
      expect(firstCategory['id'], isNotNull);
      expect(firstCategory['name'], isNotNull);
      expect(firstCategory['icon'], isNotNull);
      expect(firstCategory['description'], isNotNull);
      expect(firstCategory['priority'], isNotNull);
      expect(firstCategory['department'], isNotNull);
    });

    test('Issue statuses are properly defined', () {
      // Test that issue statuses are properly defined
      expect(AppConstants.issueStatuses, isNotEmpty);
      expect(AppConstants.issueStatuses.length, greaterThan(0));
      
      // Check first status structure
      final firstStatus = AppConstants.issueStatuses.first;
      expect(firstStatus['id'], isNotNull);
      expect(firstStatus['name'], isNotNull);
      expect(firstStatus['icon'], isNotNull);
      expect(firstStatus['color'], isNotNull);
      expect(firstStatus['description'], isNotNull);
    });

    test('Supported languages are defined', () {
      // Test that supported languages are properly defined
      expect(AppConstants.supportedLanguages, isNotEmpty);
      expect(AppConstants.supportedLanguages.length, greaterThan(0));
      
      // Check that English is supported
      final englishLanguage = AppConstants.supportedLanguages
          .firstWhere((lang) => lang['code'] == 'en');
      expect(englishLanguage['name'], equals('English'));
      expect(englishLanguage['nativeName'], equals('English'));
    });

    test('API endpoints are configured', () {
      // Test API configuration
      expect(AppConstants.baseUrl, isNotEmpty);
      expect(AppConstants.reportIssueEndpoint, isNotEmpty);
      expect(AppConstants.getIssuesEndpoint, isNotEmpty);
      expect(AppConstants.updateIssueEndpoint, isNotEmpty);
      expect(AppConstants.authEndpoint, isNotEmpty);
    });

    test('File upload limits are reasonable', () {
      // Test file upload configuration
      expect(AppConstants.maxImageSize, greaterThan(0));
      expect(AppConstants.maxVideoSize, greaterThan(0));
      expect(AppConstants.maxImagesPerIssue, greaterThan(0));
      expect(AppConstants.maxImagesPerIssue, lessThanOrEqualTo(10)); // Reasonable limit
    });

    testWidgets('App theme is configured correctly', (WidgetTester tester) async {
      // Build a simple MaterialApp with our theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Verify theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('Basic widget can be created', (WidgetTester tester) async {
      // Test that we can create a basic widget with our theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: Text(AppConstants.appName),
            ),
            body: Center(
              child: Text(AppConstants.appTagline),
            ),
          ),
        ),
      );

      // Verify the widgets are created successfully
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
