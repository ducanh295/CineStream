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
) else (
    del /q "%OUTPUT_DIR%\*.ts" "%OUTPUT_DIR%\*.m3u8" >nul 2>&1
)

echo.
echo [*] Dang tien hanh bam video thanh cac phan doan HLS 6 giay...
echo [*] Tep dau vao: "%INPUT_FILE%"
echo [*] Thu muc xuat: "%OUTPUT_DIR%"
echo.

REM Su dung GPU NVIDIA NVENC (RTX 3050) de chuyen doi sieu toc sang H.264
REM Giup xu ly tat ca cac file YouTube (AV1, VP9) thanh video HLS phat duoc ca hinh lan tieng
echo [*] Dang su dung card do hoa NVIDIA NVENC de ma hoa sang H.264...
ffmpeg -y -i "%INPUT_FILE%" -c:v h264_nvenc -preset p4 -b:v 2200k -c:a copy -start_number 0 -hls_time 6 -hls_list_size 0 -f hls "%OUTPUT_DIR%\master.m3u8"

if %ERRORLEVEL% NEQ 0 (
    echo [*] GPU khong kha dung, tu dong chuyen sang ma hoa CPU (libx264)...
    ffmpeg -y -i "%INPUT_FILE%" -c:v libx264 -preset veryfast -b:v 2000k -c:a copy -start_number 0 -hls_time 6 -hls_list_size 0 -f hls "%OUTPUT_DIR%\master.m3u8"
)

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
