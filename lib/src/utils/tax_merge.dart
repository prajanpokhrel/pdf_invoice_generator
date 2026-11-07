import '../models/tax.dart';

/// Combines the `tax:` shortcut and the `taxes:` list used by constructors.
///
/// Returns `null` when neither is given. Throws [ArgumentError] when both
/// are given, because it is unclear which one the caller meant.
List<Tax>? mergeTaxes(Tax? tax, List<Tax>? taxes) {
  if (tax != null && taxes != null) {
    throw ArgumentError('Pass either `tax` or `taxes`, not both.');
  }
  if (taxes != null) return List.unmodifiable(taxes);
  if (tax != null) return List.unmodifiable([tax]);
  return null;
}
