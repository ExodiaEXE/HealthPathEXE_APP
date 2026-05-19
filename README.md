# HealthPath (Flutter)

Mobile app chuyển từ prototype web [`remove-companion`](../remove-companion/).

## Chạy (mock backend)

**Android Studio:** mở folder `health` (có `pubspec.yaml`), không mở `health/android`. Run config **Flutter → main.dart**.

```powershell
.\scripts\run_dev.ps1
```

Hoặc:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL= --dart-define=JWT_ISSUER=
```

**Windows:** bật [Developer Mode](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development) nếu `flutter pub get` báo lỗi symlink.

## Tài liệu

Xem [`healthpath-mobile-docs`](../healthpath-mobile-docs/README.md) — kiến trúc, backlog, test, rollback.

## Cấu trúc chính

- `lib/core/` — config, theme, JWT, secure storage
- `lib/features/` — auth, home, audio, team, settings, payment
- `lib/companion/` — module chat tái sử dụng
- `lib/shared/` — models, mock data, providers

## Bảo mật

Không commit file `.env` hay key thật. Production dùng `--dart-define` hoặc CI secrets — xem `.env.example`.
