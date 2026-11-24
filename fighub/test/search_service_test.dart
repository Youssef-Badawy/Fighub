import 'package:flutter_test/flutter_test.dart';
import 'package:fighub/search_service.dart';

void main() {
  group('SearchService', () {
    test('empty query keeps all products', () {
      expect(SearchService.matches('Marvel figure', ''), isTrue);
      expect(SearchService.matches('Marvel figure', '   '), isTrue);
    });

    test('matches case-insensitive English phrases', () {
      expect(SearchService.matches('Marvel Spider Figure', 'spider'), isTrue);
      expect(SearchService.matches('Marvel Spider Figure', 'DC Batman'), isFalse);
    });

    test('normalizes common Arabic letter variants and diacritics', () {
      expect(SearchService.matches('ألعاب مُجسّمات', 'العاب مجسمات'), isTrue);
      expect(SearchService.matches('فتى فضاء', 'فتي فضاء'), isTrue);
      expect(SearchService.matches('مكتبة مجسمات', 'مكتبه مجسمات'), isTrue);
    });

    test('requires every query token to match', () {
      expect(SearchService.matches('تيشيرت فضاء أزرق', 'تيشيرت فضاء'), isTrue);
      expect(SearchService.matches('تيشيرت فضاء أزرق', 'تيشيرت مارفل'), isFalse);
    });

    test('handles punctuation and malformed-looking text safely', () {
      expect(SearchService.matches('Spider-Man: No Way Home!', 'spider man'), isTrue);
      expect(SearchService.matches('', 'anything'), isFalse);
    });

    test('ranks exact phrases above partial matches', () {
      expect(SearchService.score('Marvel Spider', 'Marvel Spider'),
          greaterThan(SearchService.score('Marvel Spider Figure', 'Marvel Spider')));
    });
  });
}
