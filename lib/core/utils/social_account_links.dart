/// Hiển thị / mở liên kết tài khoản mạng xã hội (email tổng hợp từ backend).
class SocialAccountLinks {
  SocialAccountLinks._();

  /// Backend tạo `{facebookUserId}@facebook.com` khi không có email thật.
  static String? facebookProfileId(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return null;
    if (email.substring(at + 1).toLowerCase() != 'facebook.com') return null;
    final id = email.substring(0, at);
    if (!RegExp(r'^\d+$').hasMatch(id)) return null;
    return id;
  }

  static Uri? facebookProfileUri(String email) {
    final id = facebookProfileId(email);
    if (id == null) return null;
    return Uri.parse('https://www.facebook.com/profile.php?id=$id');
  }

  static String facebookLinkLabel(String email) {
    final id = facebookProfileId(email);
    if (id == null) return email;
    return 'facebook.com/profile?id=$id';
  }
}
