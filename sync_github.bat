@echo off
echo ===================================================
echo   🥬 SESAAT APPS - AUTO GITHUB SYNC (byomanisme)
echo ===================================================
echo.
git add .
set /p commit_msg="Masukkan pesan commit (tekan Enter untuk default): "
if "%commit_msg%"=="" set commit_msg="Update project $(date /t) $(time /t)"
git commit -m "%commit_msg%"
echo.
echo Mengunggah perubahan ke GitHub...
git push origin main
echo.
echo ===================================================
echo   🎉 SINKRONISASI SELESAI! AKTIVITAS GITHUB TERCATAT
echo ===================================================
pause
