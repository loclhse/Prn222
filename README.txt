📋 HƯỚNG DẪN HOÀN CHỈNH
mở powershell
Bước 1: Tạo thư mục mới
Bước 2: Lưu 7 files PowerShell
Tạo các file sau trong thư mục mới:

master-improved.ps1 (từ artifact đầu tiên)
part1-dal-improved.ps1 (từ artifact thứ 2)
part2-bll-improved.ps1 (từ artifact thứ 3)
part3-web-improved.ps1 (từ artifact thứ 4)
part3-web-improved-controllers.ps1 (từ artifact thứ 5)
part3-web-improved-areas.ps1 (từ artifact thứ 6)
part3-web-improved-views.ps1 (từ artifact thứ 7)
part3-web-improved-views2.ps1 (từ artifact thứ 8)

Bước 3: Chạy installer
powershell -ExecutionPolicy Bypass -File .\master-improved.ps1
Bước 4: Sau khi cài đặt xong
dotnet run --project CarShop.Web
Mở browser: http://localhost:5000