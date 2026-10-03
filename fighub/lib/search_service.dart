class SearchService {
  static String normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool matches(
    String text,
    String query,
  ) {
    final normalizedText = normalize(text);
    final normalizedQuery = normalize(query);

    if (normalizedQuery.isEmpty) {
      return true;
    }

    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }

    return _hasCloseMatch(
      normalizedText,
      normalizedQuery,
    );
  }

  static bool _hasCloseMatch(
    String text,
    String query,
  ) {
    if (query.length < 3) {
      return false;
    }

    final words = text.split(' ');

    for (final word in words) {
      if (_levenshteinDistance(word, query) <=
          _allowedDistance(query.length)) {
        return true;
      }
    }

    if (text.length >= query.length) {
      for (int i = 0;
          i <= text.length - query.length;
          i++) {
        final part = text.substring(
          i,
          i + query.length,
        );

        if (_levenshteinDistance(part, query) <=
            _allowedDistance(query.length)) {
          return true;
        }
      }
    }

    return false;
  }

  static int _allowedDistance(int length) {
    if (length <= 4) {
      return 1;
    }

    if (length <= 8) {
      return 2;
    }

    return 3;
  }

  static int _levenshteinDistance(
    String a,
    String b,
  ) {
    if (a == b) {
      return 0;
    }

    if (a.isEmpty) {
      return b.length;
    }

    if (b.isEmpty) {
      return a.length;
    }

    final previousRow =
        List<int>.generate(
      b.length + 1,
      (index) => index,
    );

    for (int i = 0; i < a.length; i++) {
      final currentRow =
          List<int>.filled(
        b.length + 1,
        0,
      );

      currentRow[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        final insertCost =
            currentRow[j] + 1;

        final deleteCost =
            previousRow[j + 1] + 1;

        final replaceCost =
            previousRow[j] +
                (a[i] == b[j] ? 0 : 1);

        currentRow[j + 1] =
            [
              insertCost,
              deleteCost,
              replaceCost,
            ].reduce(
              (value, element) =>
                  value < element
                      ? value
                      : element,
            );
      }

      for (int j = 0; j < currentRow.length; j++) {
        previousRow[j] = currentRow[j];
      }
    }

    return previousRow[b.length];
  }
}