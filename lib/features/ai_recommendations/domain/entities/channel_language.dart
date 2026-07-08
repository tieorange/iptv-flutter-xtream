/// The four languages this feature filters live channels down to. There is
/// no language field anywhere in the Xtream API — categories are opaque
/// `{id, name}` strings the provider names however it likes.
enum ChannelLanguage { english, russian, polish, ukrainian }

extension ChannelLanguageLabel on ChannelLanguage {
  String get label => switch (this) {
        ChannelLanguage.english => 'English',
        ChannelLanguage.russian => 'Russian',
        ChannelLanguage.polish => 'Polish',
        ChannelLanguage.ukrainian => 'Ukrainian',
      };
}

const _englishKeywords = {
  'english',
  'britain',
  'british',
  'england',
  'america',
  'american',
  'ireland',
  'irish',
  'canada',
  'australia',
};
const _russianKeywords = {'russia', 'russian', 'рус', 'россия'};
const _polishKeywords = {'poland', 'polish', 'polska', 'polskie', 'polski'};
const _ukrainianKeywords = {'ukraine', 'ukrainian', 'ukraina', 'україна', 'укр'};

/// Heuristic keyword matcher over a raw category name — there's no real
/// language taxonomy across Xtream providers, only inconsistently-named
/// categories (e.g. `"RU| Russia HD"`, `"PL: TVP 1"`, `"USA - CNN"`).
///
/// Deliberately does NOT match bare country-code prefixes like `"uk"`/`"us"`
/// as English: on at least one real panel, `"UK|"` is used both for British
/// content and for a single Ukrainian category (`"UK| UKRAINE HD/4K"`), and
/// `"USA"` shows up inside Arabic categories that are merely timezone-shifted
/// for a US audience (e.g. `"AR| MBC +6H USA"`). Matching only on explicit,
/// unambiguous language words avoids both false positives. A category name
/// containing more than one language's keywords matches all of them.
Set<ChannelLanguage> matchCategoryLanguages(String categoryName) {
  final tokens = categoryName
      .toLowerCase()
      .split(RegExp(r'[^a-zа-яіїєʼ]+'))
      .where((t) => t.isNotEmpty)
      .toSet();

  final matches = <ChannelLanguage>{};
  if (tokens.any(_englishKeywords.contains)) matches.add(ChannelLanguage.english);
  if (tokens.any(_russianKeywords.contains)) matches.add(ChannelLanguage.russian);
  if (tokens.any(_polishKeywords.contains)) matches.add(ChannelLanguage.polish);
  if (tokens.any(_ukrainianKeywords.contains)) matches.add(ChannelLanguage.ukrainian);
  return matches;
}
