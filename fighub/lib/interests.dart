class FigHubInterests {
  static const List<String> all = [
    'Marvel',
    'DC',
    'Disney',
    'Star Wars',
    'Anime',
    'Game of Thrones',
    'Transformers',
    'Pokémon',
    'Harry Potter',
    'Gaming',
    'Movies & TV',
    'Horror',
    'Sci-Fi',
    'Fantasy',
    'WWE',
    'Other',
  ];

  static bool matchesInterest({
    required String interest,
    required String category,
  }) {
    final normalizedInterest =
        interest.trim().toLowerCase();

    final normalizedCategory =
        category.trim().toLowerCase();

    if (normalizedInterest.isEmpty ||
        normalizedCategory.isEmpty) {
      return false;
    }

    if (normalizedInterest == normalizedCategory) {
      return true;
    }

    switch (normalizedInterest) {
      case 'sci-fi':
        return normalizedCategory == 'star wars' ||
            normalizedCategory == 'transformers';

      case 'fantasy':
        return normalizedCategory == 'game of thrones' ||
            normalizedCategory == 'harry potter';

      case 'movies & tv':
        return normalizedCategory == 'game of thrones' ||
            normalizedCategory == 'harry potter' ||
            normalizedCategory == 'star wars';

      default:
        return false;
    }
  }
}
