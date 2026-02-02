@echo off
echo Getting SHA-1 fingerprint for debug keystore...
echo.

REM Try common Java installation paths
set JAVA_PATHS="%JAVA_HOME%\bin" "%ProgramFiles%\Java\jdk*\bin" "%ProgramFiles%\Java\jre*\bin" "%ProgramFiles(x86)%\Java\jdk*\bin" "%ProgramFiles(x86)%\Java\jre*\bin"

for %%i in (%JAVA_PATHS%) do (
    if exist "%%~i\keytool.exe" (
        echo Found keytool at: %%~i
        "%%~i\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr SHA1
        goto :end
    )
)

echo Java/keytool not found in common locations.
echo Please install Java JDK or add it to your PATH.
echo.
echo Alternative: Use Android Studio:
echo 1. Open Android Studio
echo 2. Go to File ^> Project Structure ^> Modules ^> app ^> Signing
echo 3. Or use Gradle: ./gradlew signingReport

:end
pause
