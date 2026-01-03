@echo off
echo ===============================
echo Cleanup Script Started
echo ===============================
echo.

:: 1. Delete Windows Temp files
echo Cleaning Windows Temp...
del /q/f/s %TEMP%\*
rd /s /q %TEMP%
mkdir %TEMP%
echo Done.

:: 2. Delete user Temp files
echo Cleaning User Temp...
del /q/f/s C:\Windows\Temp\*
rd /s /q C:\Windows\Temp
mkdir C:\Windows\Temp
echo Done.

:: 3. Clear Maven Repository cache (~\.m2\repository)
echo Cleaning Maven cache...
rd /s /q "%USERPROFILE%\.m2\repository"
echo Done.

:: 4. Clear Gradle cache (~\.gradle\caches)
echo Cleaning Gradle cache...
rd /s /q "%USERPROFILE%\.gradle\caches"
echo Done.

:: 5. Clean Windows Package Cache
echo Cleaning Windows Update cache...
net stop wuauserv
rd /s /q C:\Windows\SoftwareDistribution\Download
net start wuauserv
echo Done.

:: 6. Clean Chocolatey / Other Package Caches (Optional)
:: echo Cleaning Chocolatey cache...
:: choco clean --yes
:: echo Done.

echo.
echo ===============================
echo Cleanup Script Finished
echo ===============================
pause
