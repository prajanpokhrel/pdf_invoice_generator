import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Where the logo image comes from.
///
/// Prefer [InvoiceLogo.memory] or [InvoiceLogo.asset]: they work offline and
/// are the most reliable. [InvoiceLogo.network] downloads the image during
/// PDF generation, so it needs an internet connection at that moment.
///
/// Supported formats are PNG and JPEG. Problems loading or decoding the
/// image are reported as an `InvoiceImageException`.
@immutable
sealed class InvoiceLogo {
  const InvoiceLogo();

  /// A logo from raw image bytes (PNG or JPEG), for example from a file
  /// picker or a database.
  const factory InvoiceLogo.memory(Uint8List bytes) = MemoryInvoiceLogo;

  /// A logo from a Flutter asset bundled with the app, for example
  /// `'assets/logo.png'`. The path must be listed under `flutter: assets:`
  /// in the app's `pubspec.yaml`.
  const factory InvoiceLogo.asset(String assetPath) = AssetInvoiceLogo;

  /// A logo downloaded from [url] when the PDF is generated.
  ///
  /// Requires network access at generation time.
  const factory InvoiceLogo.network(String url) = NetworkInvoiceLogo;
}

/// Logo stored as bytes in memory. Created by [InvoiceLogo.memory].
///
/// Two instances are equal only when they share the same byte buffer, so
/// comparing invoices never has to scan large images.
final class MemoryInvoiceLogo extends InvoiceLogo {
  /// Creates a logo from [bytes].
  const MemoryInvoiceLogo(this.bytes);

  /// The encoded image (PNG or JPEG).
  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      other is MemoryInvoiceLogo && identical(other.bytes, bytes);

  @override
  int get hashCode => identityHashCode(bytes);

  @override
  String toString() => 'InvoiceLogo.memory(${bytes.length} bytes)';
}

/// Logo loaded from a Flutter asset. Created by [InvoiceLogo.asset].
final class AssetInvoiceLogo extends InvoiceLogo {
  /// Creates a logo from the asset at [assetPath].
  const AssetInvoiceLogo(this.assetPath);

  /// Asset key, for example `assets/logo.png`.
  final String assetPath;

  @override
  bool operator ==(Object other) =>
      other is AssetInvoiceLogo && other.assetPath == assetPath;

  @override
  int get hashCode => assetPath.hashCode;

  @override
  String toString() => 'InvoiceLogo.asset($assetPath)';
}

/// Logo downloaded over the network. Created by [InvoiceLogo.network].
final class NetworkInvoiceLogo extends InvoiceLogo {
  /// Creates a logo downloaded from [url].
  const NetworkInvoiceLogo(this.url);

  /// Image URL.
  final String url;

  @override
  bool operator ==(Object other) =>
      other is NetworkInvoiceLogo && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'InvoiceLogo.network($url)';
}
