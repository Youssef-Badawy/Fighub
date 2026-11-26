/// Safe, local-first search helpers for FigHub's product catalog.
///
/// Search is intentionally pure: malformed or empty input never throws and
/// an empty query never filters the product feed.
class SearchService {
  static final RegExp _arabicMarks = RegExp(r'[\u064B-\u065F\u0670\u0640]');
  static final RegExp _separators = RegExp(r'[^\u0600-\u06FFa-z0-9]+');
  static final RegExp _spaces = RegExp(r'\s+');

  static String normalize(String value) {
    try {
      return value
          .toLowerCase()
          .replaceAll(_arabicMarks, '')
          .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
          .replaceAll('ى', 'ي')
          .replaceAll('ة', 'ه')
          .replaceAll('ؤ', 'و')
          .replaceAll('ئ', 'ي')
          .replaceAll(_separators, ' ')
          .replaceAll(_spaces, ' ')
          .trim();
    } catch (_) {
      return '';
    }
  }

  /// Returns a relevance score; zero means no match.
  ///
  /// Exact phrase matches rank highest, followed by token-prefix matches.
  /// This avoids fuzzy-distance scans over long descriptions on every rebuild.
  static int score(String text, String query) {
    final normalizedText = normalize(text);
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty || normalizedText.isEmpty) return 0;
    if (normalizedText == normalizedQuery) return 100;
    if (normalizedText.contains(normalizedQuery)) return 80;

    final queryWords = normalizedQuery.split(' ').where((word) => word.isNotEmpty).toList();
    if (queryWords.isEmpty) return 0;
    final textWords = normalizedText.split(' ').toSet();
    var matched = 0;
    for (final queryWord in queryWords) {
      if (textWords.any((word) => word == queryWord || word.startsWith(queryWord))) {
        matched++;
      }
    }
    if (matched != queryWords.length) return 0;
    return 40 + matched;
  }

  static bool matches(String text, String query) {
    if (normalize(query).isEmpty) return true;
    return score(text, query) > 0;
  }
}
