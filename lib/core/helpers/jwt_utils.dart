import 'dart:convert';

String? getUidFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload['uid'];
  } catch (e) {
    print("JWT parse error: $e");
    return null;
  }
}
