@echo off
chcp 65001 >nul
echo ========================================================
echo   CineStream - Cong cu nap Co so du lieu PostgreSQL
echo ========================================================
echo.

set PGPASSWORD=123
set PSQL_BIN=C:\Program Files\PostgreSQL\18\bin\psql.exe

if not exist "%~dp0cinestream_backup.sql" (
    echo [Loi] Khong tim thay tep cinestream_backup.sql trong thu muc Backend!
    echo.
    pause
    exit /b 1
)

echo Dang nap du lieu vao co so du lieu CineStreamDb...
echo.

if exist "%PSQL_BIN%" (
    "%PSQL_BIN%" -U postgres -d CineStreamDb -f "%~dp0cinestream_backup.sql"
) else (
    psql -U postgres -d CineStreamDb -f "%~dp0cinestream_backup.sql"
)

if %errorlevel% equ 0 (
    echo.
    echo [Thanh cong] Da nap du lieu hoan tat vao co so du lieu CineStreamDb!
) else (
    echo.
    echo [Loi] Co loi xay ra trong qua trinh nap du lieu. Vui long kiem tra lai.
)

echo.
pause
