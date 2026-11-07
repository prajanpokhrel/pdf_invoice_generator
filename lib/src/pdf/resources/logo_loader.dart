// Internal: turns an InvoiceLogo into an image the PDF can draw.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import '../../exceptions/invoice_exceptions.dart';
import '../../models/invoice_logo.dart';

/// JPEGs up to this size are embedded as-is (fast, no quality loss).
const int maxPassThroughJpegBytes = 1024 * 1024;

/// Larger images are scaled down so their longest side is this many pixels.
/// A logo is printed at most a few centimetres wide, so this is plenty.
const int maxLogoDimension = 1024;

/// Network logos give up after this long.
const Duration networkTimeout = Duration(seconds: 15);

/// Loads [logo]. Returns `null` when there is no logo.
///
/// Throws [InvoiceImageException] when the image cannot be loaded or
/// decoded. [httpClient] is only used for network logos (tests inject one).
Future<pw.ImageProvider?> loadLogo(
  InvoiceLogo? logo, {
  http.Client? httpClient,
}) async {
  if (logo == null) return null;
  final bytes = switch (logo) {
    MemoryInvoiceLogo(:final bytes) => bytes,
    AssetInvoiceLogo(:final assetPath) => await _loadAsset(assetPath),
    NetworkInvoiceLogo(:final url) => await _download(url, httpClient),
  };
  return decodeLogo(bytes);
}

Future<Uint8List> _loadAsset(String path) async {
  try {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } on Object catch (e) {
    throw InvoiceImageException(
      'Logo asset "$path" could not be loaded. Check that it is listed under '
      '"flutter: assets:" in your pubspec.yaml.',
      cause: e,
    );
  }
}

Future<Uint8List> _download(String url, http.Client? client) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    throw InvoiceImageException('Logo URL "$url" is not a valid URL.');
  }
  final owned = client == null;
  final c = client ?? http.Client();
  try {
    final response = await c.get(uri).timeout(networkTimeout);
    if (response.statusCode != 200) {
      throw InvoiceImageException(
        'Logo download from "$url" failed with HTTP ${response.statusCode}.',
      );
    }
    return response.bodyBytes;
  } on InvoiceImageException {
    rethrow;
  } on Object catch (e) {
    throw InvoiceImageException(
      'Logo download from "$url" failed. Network logos need an internet '
      'connection; consider InvoiceLogo.memory or InvoiceLogo.asset.',
      cause: e,
    );
  } finally {
    if (owned) c.close();
  }
}

/// Validates [bytes] and converts them to a PDF image.
///
/// * Empty or unrecognised data throws [InvoiceImageException].
/// * Small JPEGs are passed through unchanged.
/// * Everything else (PNG, GIF, WebP, BMP, TIFF, large JPEGs) is decoded
///   now, so corrupt files fail here with a clear message instead of later
///   inside the PDF library, and is scaled down to [maxLogoDimension].
pw.ImageProvider decodeLogo(Uint8List bytes) {
  if (bytes.isEmpty) {
    throw const InvoiceImageException('Logo image is empty (0 bytes).');
  }
  img.Decoder? decoder;
  try {
    decoder = img.findDecoderForData(bytes);
  } on Object {
    // Some versions of package:image throw (for example a RangeError) when
    // probing very short data instead of returning null.
    decoder = null;
  }
  // Only formats with a reliable file signature are accepted. Formats such
  // as TGA have almost no header, so random bytes can look like a "valid"
  // TGA and would silently print garbage instead of failing.
  final supported = decoder is img.PngDecoder ||
      decoder is img.JpegDecoder ||
      decoder is img.GifDecoder ||
      decoder is img.BmpDecoder ||
      decoder is img.WebPDecoder ||
      decoder is img.TiffDecoder;
  if (decoder == null || !supported) {
    throw const InvoiceImageException(
      'Logo image format is not recognised or the data is corrupt. '
      'Supported formats: PNG, JPEG, GIF, BMP, WebP, TIFF.',
    );
  }

  if (decoder is img.JpegDecoder && bytes.length <= maxPassThroughJpegBytes) {
    try {
      return pw.MemoryImage(bytes);
    } on Object catch (e) {
      throw InvoiceImageException('Logo JPEG could not be read.', cause: e);
    }
  }

  img.Image? image;
  try {
    image = decoder.decode(bytes);
  } on Object catch (e) {
    throw InvoiceImageException('Logo image could not be decoded.', cause: e);
  }
  if (image == null) {
    throw const InvoiceImageException(
      'Logo image could not be decoded (corrupt or truncated file).',
    );
  }

  final longest = math.max(image.width, image.height);
  if (longest > maxLogoDimension) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxLogoDimension)
        : img.copyResize(image, height: maxLogoDimension);
  }
  return pw.ImageImage(image);
}
