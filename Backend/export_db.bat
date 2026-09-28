@echo off
chcp 65001 >nul
echo ========================================================
echo   CineStream - Cong cu xuat Co so du lieu PostgreSQL
echo ========================================================
echo.

set PGPASSWORD=123
set PG_BIN=C:\Program Files\PostgreSQL\18\bin\pg_dump.exe

if exist "%PG_BIN%" (
    "%PG_BIN%" -U postgres -d CineStreamDb -F p -b -v -f "%~dp0cinestream_backup.sql"
) else (
    pg_dump -U postgres -d CineStreamDb -F p -b -v -f "%~dp0cinestream_backup.sql"
)

if %errorlevel% equ 0 (
    echo.
    echo [Thanh cong] Da xuat du lieu ra tep: %~dp0cinestream_backup.sql
) else (
    echo.
    echo [Loi] Khong the xuat du lieu. Vui long kiem tra lai dich vu PostgreSQL va mat khau.
)

echo.
pause
