import 'dart:math';
import 'package:onam_pass/utils/constants.dart';

/// Generates and validates pass IDs.
class QrService {
  static final _random = Random.secure();

  /// Generate a unique pass ID, e.g. ONAM-8F42A91C
  static String generatePassId() {
    const chars = '0123456789ABCDEF';
    final sb = StringBuffer(PassConstants.prefix);
    for (int i = 0; i < PassConstants.idLength; i++) {
      sb.write(chars[_random.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  /// Returns true if the string looks like a valid ONAM- pass ID.
  static bool isValidPassIdFormat(String value) {
    final regex = RegExp(
      r'^ONAM-[0-9A-F]{8}$',
      caseSensitive: false,
    );
    return regex.hasMatch(value);
  }
}
