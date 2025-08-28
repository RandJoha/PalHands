import 'package:flutter_test/flutter_test.dart';
import 'package:palhands/shared/services/reports_service.dart';

void main() {
  group('ReportsService Integration', () {
    test('should handle anonymous feature suggestion without null error', () async {
      final reportsService = ReportsService();
      
      try {
        final result = await reportsService.createReport(
          reportCategory: 'feature_suggestion',
          description: 'Test feature suggestion for integration test',
          ideaTitle: 'Integration Test Feature',
          communityBenefit: 'This will help test the integration',
          contactName: 'Integration Test User',
          contactEmail: 'integration-test@example.com',
        );
        
        // The result should be a map
        expect(result, isA<Map<String, dynamic>>());
        
        // Should have a success field
        expect(result.containsKey('success'), isTrue);
        
        // If successful, should have data
        if (result['success'] == true) {
          expect(result.containsKey('data'), isTrue);
          expect(result['data'], isA<ReportModel>());
        }
        
        print('✅ Integration test result: $result');
      } catch (e) {
        // If there's an error, it should not be a null type error
        expect(e.toString(), isNot(contains('type \'Null\' is not a subtype of type \'String\'')));
        print('⚠️ Expected error: $e');
      }
    });
  });
}
