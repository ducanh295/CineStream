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
set DEFAULT_NAME=%~n1

echo [*] Tep video dau vao: "%~nx1"
echo.
set /p FOLDER_NAME="Nhap ten thu muc phim [Nhan ENTER de dung mac dinh: %DEFAULT_NAME%]: "

if "%FOLDER_NAME%"=="" (
    set FOLDER_NAME=%DEFAULT_NAME%
)

set OUTPUT_DIR=%~dp0wwwroot\videos\%FOLDER_NAME%

REM Kiem tra an toan du lieu: Neu thu muc da ton tai thi yeu cau xac nhan truoc khi xoa de
if exist "%OUTPUT_DIR%" (
    echo.
    echo [CANH BAO]: Thu muc "%FOLDER_NAME%" da ton tai trong wwwroot\videos!
    echo Neu tiep tuc, cac phan doan video cu trong thu muc nay se bi xoa de cap nhat moi.
    set /p CONFIRM="Ban co chac chan muon ghi de khong? (Y/N): "
    if /i not "!CONFIRM!"=="Y" if /i not "!CONFIRM!"=="y" (
        if /i "%CONFIRM%" NEQ "Y" if /i "%CONFIRM%" NEQ "y" (
            echo.
            echo [DA HUY]: Thao tac da duoc huy bo de bao ve du lieu cu.
            pause
            exit /b
        )
    )
    del /q "%OUTPUT_DIR%\*.ts" "%OUTPUT_DIR%\*.m3u8" >nul 2>&1
) else (
    mkdir "%OUTPUT_DIR%"
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
    echo Duong dan tuong doi de chon tren WebAdmin:
    echo /videos/%FOLDER_NAME%/master.m3u8
    echo.
    echo Huong dan su dung tren WebAdmin:
    echo 1. Vao muc Them/Sua phim tren WebAdmin.
    echo 2. Bam vao nut 'Kho HLS noi bo' tai muc Video URL.
    echo 3. Nhap chuot chon thu muc '%FOLDER_NAME%' de tu dong dien 1-click!
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
