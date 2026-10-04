import 'package:flutter_test/flutter_test.dart';
import 'package:rad_browser/features/search/data/rad_search_service.dart';
import 'package:rad_browser/features/search/data/rad_smart_search_service.dart';

void main() {
  group('RadSmartSearchService', () {
    final service = RadSmartSearchService();

    test('returns a calculator answer for simple expressions', () {
      final answer = service.answerBox('12 * 3');
      expect(answer, isNotNull);
      expect(answer!.value, '36');
      expect(answer.label, 'ماشین حساب');
    });

    test('does not return calculator answer for division by zero', () {
      expect(service.answerBox('10 / 0'), isNull);
    });

    test('ranking prefers stronger query matches while keeping real results', () {
      final input = <RadSearchItem>[
        const RadSearchItem(
          title: 'خبر عمومی',
          url: 'http://example.com/general',
          snippet: 'مطالب عمومی',
        ),
        const RadSearchItem(
          title: 'فوتبال ایران امروز',
          url: 'https://example.ir/football',
          snippet: 'آخرین خبرهای فوتبال ایران',
        ),
      ];

      final ranked = service.rankResults('فوتبال ایران', input);
      expect(ranked.first.url, 'https://example.ir/football');
      expect(ranked.length, input.length);
    });
  });
}
