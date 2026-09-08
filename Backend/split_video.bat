@echo off
chcp 65001 >nul
echo ==========================================================
echo        CINESTREAM - CONG CU BAM PHIM HLS CHUAN
echo ==========================================================
echo.

if "%~1"=="" (
    echo [HUONG DAN]: Keo va tha truc tiep file video .mp4 vao file split_video.bat nay!
    echo Hoac go: split_video.bat "duong_dan_den_file_phim.mp4"
    echo.
    pause
    exit /b
)

set INPUT_FILE=%~1
set /p MOVIE_ID="Nhap ID cua bo phim trong Database (vi du: 1, 2, 4): "

if "%MOVIE_ID%"=="" (
    echo [LOI]: ID phim khong duoc de trong!
    pause
    exit /b
)

set OUTPUT_DIR=%~dp0wwwroot\videos\%MOVIE_ID%

if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
)

echo.
echo [*] Dang tien hanh bam video thanh cac phan doan HLS 6 giay...
echo [*] Tep dau vao: "%INPUT_FILE%"
echo [*] Thu muc xuat: "%OUTPUT_DIR%"
echo.

ffmpeg -y -i "%INPUT_FILE%" -codec: copy -start_number 0 -hls_time 6 -hls_list_size 0 -f hls "%OUTPUT_DIR%\master.m3u8"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================================
    echo [THANH CONG]: Da bam phim xong vao thu muc:
    echo %OUTPUT_DIR%
    echo.
    echo Duong dan videoUrl de luu vao Database:
    echo http://localhost:5182/videos/%MOVIE_ID%/master.m3u8
    echo.
    echo Ban co the kiem tra xem thu ngay tai:
    echo http://localhost:5182/player.html
    echo ==========================================================
) else (
    echo.
    echo [THAT BAI]: Co loi xay ra trong qua trinh bam video! Vui long kiem tra lai file dau vao.
)

echo.
pause
