# HealthPath (Flutter)

## Cấu hình API — file `.env` (khuyến nghị)

Giống backend (`health_backend/.env`), app đọc **một file env** ở thư mục gốc project:

```powershell
cd d:\exe_project\health
.\scripts\setup_env.ps1    # tạo .env từ .env.example (lần đầu)
```

Sửa `d:\exe_project\health\.env`:

```env
API_BASE_URL=https://10.0.2.2:7232
JWT_ISSUER=healthpath
```

| Môi trường | `API_BASE_URL` gợi ý |
|------------|----------------------|
| Backend VS **https :7232** + Android Emulator | `https://10.0.2.2:7232` |
| Backend **http :5048** + Emulator | `http://10.0.2.2:5048` |
| Windows desktop (cùng máy backend) | `https://localhost:7232` |
| Demo offline (mock) | để trống `API_BASE_URL=` |

Sau đó chạy **bình thường** — Android Studio F5 / `flutter run` — **không cần** thêm `--dart-define`.

Màn login: banner **xanh** = đã nối API, **cam** = offline.

## Chạy nhanh

```powershell
.\scripts\run_dev.ps1
```

Hoặc ghi `.env` tự động theo platform rồi chạy:

```powershell
.\scripts\run_with_backend.ps1              # Android → 10.0.2.2:7232
.\scripts\run_with_backend.ps1 -Platform windows
```

## Backend

Chạy API trước (Visual Studio F5 → `https://localhost:7232/swagger`).

## Auth API

| App | Backend |
|-----|---------|
| Đăng ký | `POST /api/Auth/register` |
| Đăng nhập | `POST /api/Auth/login` |
| Google / Facebook | `POST /api/Auth/social-login` |
| Khôi phục phiên | `GET /api/Users/me` |

## Ghi đè khi build CI (tùy chọn)

`--dart-define=API_BASE_URL=...` vẫn **ưu tiên hơn** `.env` nếu cần.

## Bảo mật

- `.env` đã **gitignore** — không commit.
- Chỉ commit `.env.example` (mẫu, không có secret thật).
