class AvatarHelper {
  static const String defaultStyle = 'pixel-art';
  static const String defaultSeed = 'nightpoint';

  static const List<String> styles = [
    'adventurer-neutral',
    'adventurer',
    'avataaars-neutral',
    'avataaars',
    'big-ears-neutral',
    'big-ears',
    'big-smile',
    'bottts-neutral',
    'bottts',
    'croodles-neutral',
    'croodles',
    'disco',
    'dylan',
    'fun-emoji',
    'glass',
    'glyphs',
    'icons',
    'initial-face',
    'lorelei-neutral',
    'lorelei',
    'micah',
    'miniavs',
    'notionists-neutral',
    'notionists',
    'open-peeps',
    'personas',
    'pixel-art-neutral',
    'pixel-art',
    'rings',
    'shape-grid',
    'shapes',
    'stripes',
    'thumbs',
    'toon-head',
    'triangles',
  ];

  static String buildAvatarUrl({
    required String style,
    required String seed,
  }) {
    final safeStyle = styles.contains(style) ? style : defaultStyle;
    final safeSeed = seed.trim().isEmpty ? defaultSeed : seed.trim();

    return 'https://api.dicebear.com/10.x/$safeStyle/png?seed=$safeSeed';
  }

  static String formatStyleName(String style) {
    return style
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}