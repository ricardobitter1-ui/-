/// Presets de cor para grupos (linha pastel alinhada aos quadrantes da home).
const String kDefaultGroupColorHex = '#7B8CDE';

/// Chave [SharedPreferences] — migração única de cores legadas → presets v2.
const String kGroupColorMigrationV2PrefsKey = 'group_color_migration_v2_done';

const List<String> kGroupColorPresets = <String>[
  '#7B8CDE',
  '#9B8AD4',
  '#E8A0BF',
  '#7DCFB6',
  '#E8C547',
  '#8B95B5',
  '#A0DFCD',
  '#F0D86E',
];

/// Hex legado (picker v1) → preset v2.
const Map<String, String> kLegacyGroupColorToPreset = <String, String>{
  '#0052FF': '#7B8CDE',
  '#5A189A': '#9B8AD4',
  '#FF6B6B': '#E8A0BF',
  '#2EC4B6': '#7DCFB6',
  '#FFB703': '#E8C547',
  '#2B2D42': '#8B95B5',
};

String normalizeGroupColorHexForLookup(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  if (!s.startsWith('#')) s = '#$s';
  s = s.toUpperCase();
  if (s.length == 4) {
    final r = s[1];
    final g = s[2];
    final b = s[3];
    s = '#$r$r$g$g$b$b';
  }
  return s.length == 7 ? s : s;
}

/// `null` se não for cor legada mapeada.
String? mapLegacyGroupColorToPreset(String normalizedHex) {
  return kLegacyGroupColorToPreset[normalizedHex];
}
