rem To have this file log the change being made to a log file, use the following command: cleanup.bat >>Y:\%date:~-4,4%%date:~-10,2%.log 2>&1

@echo off
Echo ---------------Start Cleanup Process----------------------
echo. |date |find "current"
echo. |time |find "current"
echo Hostname: %computername%
echo.
echo The following OverView TMP files have been deleted
forfiles /p W:\ /s /m *.TMP /d -30 /c "CMD /C DEL @FILE | ECHO @FILE"
echo OverView TMP fIles Cleanup Ended
echo.
echo The following PDF files have been deleted
forfiles /p x:\ /s /m *.PDF /d -180 /c "CMD /C DEL @FILE | ECHO @FILE"
echo PDF fIles Cleanup Ended
echo.
echo The following Cleanup Log files have been deleted
forfiles /p Y:\ /s /m *.txt /d -180 /c "CMD /C DEL @FILE | ECHO @FILE"
echo Log files Cleanup Ended
echo.
echo The following IIS Log files have been deleted
forfiles /p z:\ /s /m *.log /d -30 /c "CMD /C DEL @FILE | ECHO @FILE"
echo IIS Log files Cleanup Ended
Echo ----------------End Cleanup Process-----------------------