/// Usuwa polskie znaki i wielkie litery — do wyszukiwania „lodz” → „Łódź”.
String normalizeForSearch(String s) {
  const map = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
  };
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().trim().split('')) {
    buf.write(map[ch] ?? ch);
  }
  return buf.toString();
}

/// Czy [text] pasuje do [query] (już znormalizowanego): od początku tekstu
/// lub od początku dowolnego słowa — „bach” trafia w „Salsa / bachata”.
bool matchesQuery(String text, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  final t = normalizeForSearch(text);
  if (t.startsWith(normalizedQuery)) return true;
  return t
      .split(RegExp(r'[\s/(),-]+'))
      .any((w) => w.startsWith(normalizedQuery));
}
