class SearchService {
  static String normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\\s+'), ' ');
  }

  static bool matches(String text, String query) {
    try {
      final normalizedText = normalize(text);
      final normalizedQuery = normalize(query);

      if (normalizedQuery.isEmpty) return true;
      if (normalizedText.isEmpty) return false;
      if (normalizedText.contains(normalizedQuery)) return true;

      // Compare individual words only. This keeps unmatched searches bounded
      // and avoids the expensive substring-distance scan on long descriptions.
      final queryWords = normalizedQuery
          .split(' ')
          .where((word) => word.length >= 3)
          .take(6)
          .toList();
      if (queryWords.isEmpty) return false;

      final textWords = normalizedText.split(' ').take(120);
      for (final word in textWords) {
        for (final queryWord in queryWords) {
          if (word == queryWord ||
              (queryWord.length >= 4 && word.startsWith(queryWord))) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      // Search must never crash the home screen for malformed text.
      return false;
    }
  }
}