// Small equality helpers so models can compare lists and maps by value
// without depending on package:collection.

/// Returns `true` when [a] and [b] have the same elements in the same order.
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns `true` when [a] and [b] contain the same keys mapped to equal values.
bool mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Order-independent hash for a map, consistent with [mapEquals].
int mapHash<K, V>(Map<K, V> map) => Object.hashAllUnordered(
      map.entries.map((e) => Object.hash(e.key, e.value)),
    );
