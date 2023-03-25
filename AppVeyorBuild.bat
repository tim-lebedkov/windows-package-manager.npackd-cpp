echo on
rem This script is used by AppVeyor to build the project.
set initial_path=%path%
set version=%APPVEYOR_BUILD_VERSION:~0,-5%
SET NPACKD_CL=C:\Program Files\NpackdCL

set onecmd="%npackd_cl%\ncl.exe" path -p com.advancedinstaller.AdvancedInstallerFreeware -r [10,100)
for /f "usebackq delims=" %%x in (`%%onecmd%%`) do set ai=%%x

set onecmd="%npackd_cl%\ncl.exe" path -p org.7-zip.SevenZIP -r [9,100)
for /f "usebackq delims=" %%x in (`%%onecmd%%`) do set SEVENZIP=%%x

set onecmd="%npackd_cl%\ncl.exe" path -p exeproxy -r [0.2,1)
for /f "usebackq delims=" %%x in (`%%onecmd%%`) do set EXEPROXY=%%x

if %bits% equ 64 (call :setvars64) else (call :setvars32)
set path=%mingw%\bin;C:\msys64\mingw64\bin\

mkdir c:\builds

if %static% equ ON (call :buildquazip)
if %static% equ ON (set extra="-DQUAZIP_INCLUDE_DIRS=quazip" "-DQUAZIP_LIBRARIES=c:\builds\quazip\quazip\libquazip1-qt5.a")
if %prg% equ npackdcl (call :buildnpackdcl)
if %prg% equ clu (call :buildclu)
if %prg% equ npackd (call :buildnpackd)

goto :eof

rem ---------------------------------------------------------------------------
:setvars32
set mingw_libs=i686-w64-mingw32
set mingw=C:\msys64\mingw32
set onecmd="%npackd_cl%\ncl.exe" path -p drmingw -v 0.7.7
for /f "usebackq delims=" %%x in (`%%onecmd%%`) do set drmingw=%%x
exit /b

rem ---------------------------------------------------------------------------
:setvars64
set mingw_libs=x86_64-w64-mingw32
set mingw=C:\msys64\mingw64
set onecmd="%npackd_cl%\ncl.exe" path -p drmingw64 -v 0.7.7
for /f "usebackq delims=" %%x in (`%%onecmd%%`) do set drmingw=%%x
exit /b

rem ---------------------------------------------------------------------------
:buildquazip
cmake.exe -GNinja -S quazip -B c:\builds\quazip -DCMAKE_BUILD_TYPE=Release -DQUAZIP_QT_MAJOR_VERSION=5 -DQUAZIP_FETCH_LIBS=OFF -DBUILD_SHARED_LIBS:BOOL=OFF -DZLIB_LIBRARY_RELEASE=%mingw%\lib\libz.a -DZLIB_LIBRARY_RELEASE=%mingw%\lib\libbz2.a
if %errorlevel% neq 0 exit /b %errorlevel%

cmake.exe --build c:\builds\quazip
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b

rem ---------------------------------------------------------------------------
:buildnpackd
set path=%mingw%\bin;%ai%\bin\x86;%sevenzip%;C:\msys64\mingw64\bin
set CMAKE_PREFIX_PATH=%mingw%\%mingw_libs%
set where=c:\builds\npackdg

cmake -GNinja -S npackdg -B %where% -DCMAKE_BUILD_TYPE=MinSizeRel -DNPACKD_FORCE_STATIC:BOOL=%STATIC% %extra%
if %errorlevel% neq 0 exit /b %errorlevel%

cmake.exe --build %where%
if %errorlevel% neq 0 exit /b %errorlevel%

mkdir %where%\install
if %errorlevel% neq 0 exit /b %errorlevel%

C:\Windows\System32\xcopy.exe %where%\install %where%\install-debug /E /I /H /Y
if %errorlevel% neq 0 exit /b %errorlevel%

strip %where%\install\npackdg.exe
if %errorlevel% neq 0 exit /b %errorlevel%

copy %where%\npackdg.map %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\exchndl.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\mgwhelp.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\dbghelp.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\symsrv.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\symsrv.yes" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

7z a %where\Npackd%bits%-debug-%version%.zip %where%\install-debug -mx9	
if %errorlevel% neq 0 exit /b %errorlevel%

7z a %where%\Npackd%bits%-%version%.zip %where%\install-debug -mx9	
if %errorlevel% neq 0 exit /b %errorlevel%

copy ..\src\npackdg%bits%.aip %where%\install
if %errorlevel% neq 0 exit /b %errorlevel%

copy ..\src\app.ico %where%\install
if %errorlevel% neq 0 exit /b %errorlevel%

AdvancedInstaller.com /edit %where%\install\npackdg%bits%.aip /SetVersion %version%
if %errorlevel% neq 0 exit /b %errorlevel%

AdvancedInstaller.com /build %where%\install\npackdg%bits%.aip
if %errorlevel% neq 0 exit /b %errorlevel%

appveyor PushArtifact %where%\Npackd%bits%-%version%.zip
if %errorlevel% neq 0 exit /b %errorlevel%

appveyor PushArtifact %where%\Npackd%bits%-%version%.msi
if %errorlevel% neq 0 exit /b %errorlevel%

appveyor PushArtifact %where%\Npackd%bits%-debug-%version%.zip
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b

rem ---------------------------------------------------------------------------
:buildnpackdcl
set path=%mingw%\bin;%ai%\bin\x86;%sevenzip%;C:\msys64\mingw64\bin
set CMAKE_PREFIX_PATH=%mingw%\%mingw_libs%
set where=c:\builds\clu

cmake -GNinja -S npackdcl -B %where% -DCMAKE_BUILD_TYPE=MinSizeRel -DNPACKD_FORCE_STATIC:BOOL=%STATIC%  %extra%
if %errorlevel% neq 0 exit /b %errorlevel%

cmake.exe --build %where%
if %errorlevel% neq 0 exit /b %errorlevel%

mkdir %where%\install
if %errorlevel% neq 0 exit /b %errorlevel%

copy %where%\npackdcl.exe %where%\install
if %errorlevel% neq 0 exit /b %errorlevel%

"%EXEPROXY%\exeproxy.exe" exeproxy-copy %where%\install\ncl.exe npackdcl.exe
if %errorlevel% neq 0 exit /b %errorlevel%

C:\Windows\System32\xcopy.exe %where%\install %where%\install-debug /E /I /H /Y
if %errorlevel% neq 0 exit /b %errorlevel%

strip %where%\install\npackdcl.exe
if %errorlevel% neq 0 exit /b %errorlevel%

copy %where%\npackdcl.map %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\exchndl.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\mgwhelp.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\dbghelp.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\symsrv.dll" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

copy "%DRMINGW%\bin\symsrv.yes" %where%\install-debug
if %errorlevel% neq 0 exit /b %errorlevel%

7z a %where%\NpackdCL%bits%-debug-%version%.zip %where%\install-debug -mx9	
if %errorlevel% neq 0 exit /b %errorlevel%

7z a %where%\NpackdCL%bits%-%version%.zip %where%\install -mx9	
if %errorlevel% neq 0 exit /b %errorlevel%
	   
copy ..\src\NpackdCL%bits%.aip %where%
if %errorlevel% neq 0 exit /b %errorlevel%

copy ..\src\app.ico %where%\
if %errorlevel% neq 0 exit /b %errorlevel%

AdvancedInstaller.com /edit %where%\NpackdCL%bits%.aip /SetVersion %version%
if %errorlevel% neq 0 exit /b %errorlevel%

AdvancedInstaller.com /build %where%\NpackdCL%bits%.aip
if %errorlevel% neq 0 exit /b %errorlevel%

set path=%initial_path%

appveyor PushArtifact %where%\NpackdCL%bits%-%version%.zip
if %errorlevel% neq 0 exit /b %errorlevel%

appveyor PushArtifact %where%\NpackdCL%bits%-%version%.msi
if %errorlevel% neq 0 exit /b %errorlevel%

appveyor PushArtifact %where%\NpackdCL%bits%-debug-%version%.zip
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b

rem ---------------------------------------------------------------------------
:buildclu
set path=%mingw%\bin;%ai%\bin\x86;%sevenzip%;C:\msys64\mingw64\bin
set CMAKE_PREFIX_PATH=%mingw%\%mingw_libs%
set where=c:\builds\clu

cmake -GNinja -S clu -B %where% -DCMAKE_INSTALL_PREFIX=..\install -DNPACKD_FORCE_STATIC:BOOL=%STATIC%  %extra%
if %errorlevel% neq 0 exit /b %errorlevel%

cmake.exe --build %where%
if %errorlevel% neq 0 exit /b %errorlevel%

strip %where%\clu.exe
if %errorlevel% neq 0 exit /b %errorlevel%

7z a CLU%bits%-%version%.zip * -mx9	
if %errorlevel% neq 0 exit /b %errorlevel%
	   
copy ..\src\app.ico .
if %errorlevel% neq 0 exit /b %errorlevel%

set path=%initial_path%
appveyor PushArtifact %where%\CLU%bits%-%version%.zip
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b

rem ---------------------------------------------------------------------------
:coverity
rem Coverity build is too slow

set path=%mingw%\bin;%ai%\bin\x86;%sevenzip%;C:\msys64\mingw64\bin
set CMAKE_PREFIX_PATH=%mingw%\%mingw_libs%
mingw32-make.exe clean

"..\..\cov-analysis\bin\cov-configure.exe"  --comptype gcc --compiler C:\PROGRA~2\MINGW-~1\bin\G__~1.EXE -- -std=gnu++11
"..\..\cov-analysis\bin\cov-build.exe" --dir ..\..\cov-int mingw32-make.exe install

rem type C:\projects\Npackd\cov-int\build-log.txt

7z a cov-int.zip cov-int
if %errorlevel% neq 0 exit /b %errorlevel%

"C:\Program Files (x86)\Gow\bin\curl" --form token=%covtoken% --form email=tim.lebedkov@gmail.com -k --form file=@cov-int.zip --form version="Version" --form description="Description" https://scan.coverity.com/builds?project=Npackd
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b

