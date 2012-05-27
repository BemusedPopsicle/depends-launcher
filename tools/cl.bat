@ECHO OFF
setlocal
set _BUILDLOG=%~dp0..\obj\%~n0.log
set _TOOLCMDLINE=%~n0.exe
call "%~dp0toolcmd.bat" %*
echo Compiler Platform: %TARGET_PLATFORM%
%_TOOLCMDLINE%>"%_BUILDLOG%" 2>&1
if ERRORLEVEL 1 (
	echo Error occurred!
	type "%_BUILDLOG%"
	pause
	exit /B %ERRORLEVEL%
)
endlocal