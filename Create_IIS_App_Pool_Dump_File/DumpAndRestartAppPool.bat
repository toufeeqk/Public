setlocal ENABLEDELAYEDEXPANSION
tasklist /FI "username eq APP_POOL_NAME" /fo list>%temp%\tasklist.txt

set vidx=0
for /F "tokens=*" %%A in (%temp%\tasklist.txt) do (
    SET /A vidx=!vidx! + 1
    set var!vidx!=%%A
)
set var

set pid=%var2:~14%

echo %var1%
echo %var2%
echo %var3%
echo %var4%
echo %pid%

c:\temp\procdump.exe -accepteula -ma %pid%
echo Started: %date% %time%>>c:\temp\restartlog.txt
c:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:APP_POOL_NAME
c:\Windows\System32\inetsrv\appcmd start apppool /apppool.name:APP_POOL_NAME
echo Finished: %date% %time%>>c:\temp\restartlog.txt
move *.dmp y:\