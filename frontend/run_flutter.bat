@echo off
setlocal
set GRADLE_USER_HOME=F:\gradle_cache
cd /d "F:\GreenBin Genius\frontend"
call flutter run %*
endlocal
