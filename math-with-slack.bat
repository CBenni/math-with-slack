@ECHO OFF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Rendered math (MathJax) with Slack's desktop client
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Slack (https://slack.com) does not display rendered math. This script
:: injects MathJax (https://www.mathjax.org) into Slack's desktop client,
:: which allows you to write nice-looking inline- and display-style math
:: using familiar TeX/LaTeX syntax.
::
:: https://github.com/fsavje/math-with-slack
::
:: MIT License, Copyright 2017-2018 Fredrik Savje
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: Constants

SET "MWS_VERSION=v0.2.5"


:: User input

SET "UNINSTALL="
SET "SLACK_DIR="

:parse
IF "%~1" == "" GOTO endparse
IF "%~1" == "-u" (
	SET UNINSTALL=%~1
) ELSE (
	SET SLACK_DIR=%~1
)
SHIFT
GOTO parse
:endparse


:: Try to find slack if not provided by user

IF "%SLACK_DIR%" == "" (
	FOR /F %%t IN ('DIR /B /OD "%UserProfile%\AppData\Local\slack\app-?.*.*"') DO (
		SET "SLACK_DIR=%UserProfile%\AppData\Local\slack\%%t\resources\app.asar.unpacked\src\static"
	)
)


:: Files

SET "SLACK_MATHJAX_SCRIPT=%SLACK_DIR%\math-with-slack.js"
SET "SLACK_SSB_INTEROP=%SLACK_DIR%\ssb-interop.js"


:: Check so installation exists

IF "%SLACK_DIR%" == "" (
	ECHO Cannot find Slack installation.
	PAUSE & EXIT /B 1
)

IF NOT EXIST "%SLACK_DIR%" (
	ECHO Cannot find Slack installation at: %SLACK_DIR%
	PAUSE & EXIT /B 1
)

IF NOT EXIST "%SLACK_SSB_INTEROP%" (
	ECHO Cannot find Slack file: %SLACK_SSB_INTEROP%
	PAUSE & EXIT /B 1
)


ECHO Using Slack installation at: %SLACK_DIR%


:: Remove previous version

IF EXIST "%SLACK_MATHJAX_SCRIPT%" (
	DEL "%SLACK_MATHJAX_SCRIPT%"
)


:: Restore previous injections

FINDSTR /R /C:"math-with-slack" "%SLACK_SSB_INTEROP%" >NUL
IF %ERRORLEVEL% EQU 0 (
	IF EXIST "%SLACK_SSB_INTEROP%.mwsbak" (
		MOVE /Y "%SLACK_SSB_INTEROP%.mwsbak" "%SLACK_SSB_INTEROP%" >NUL
	) ELSE (
		ECHO Cannot restore from backup. Missing file: %SLACK_SSB_INTEROP%.mwsbak
		PAUSE & EXIT /B 1
	)
) ELSE (
	IF EXIST "%SLACK_SSB_INTEROP%.mwsbak" (
		DEL "%SLACK_SSB_INTEROP%.mwsbak"
	)
)


:: Are we uninstalling?

IF "%UNINSTALL%" == "-u" (
	ECHO math-with-slack has been uninstalled. Please restart the Slack client.
	PAUSE & EXIT /B 0
)


:: Write main script
:: TODO: FIX ON WINDOWS.
for /f "delims=: tokens=1*" %%i in ('findstr "%%MWS_VERSION%%" mathjax.js') do (
  echo %%j
) >> "%SLACK_MATHJAX_SCRIPT%"


:: Check so not already injected

FINDSTR /R /C:"math-with-slack" "%SLACK_SSB_INTEROP%" >NUL
IF %ERRORLEVEL% EQU 0 (
	ECHO File already injected: %SLACK_SSB_INTEROP%
	PAUSE & EXIT /B 1
)


:: Make backup

IF NOT EXIST "%SLACK_SSB_INTEROP%.mwsbak" (
	MOVE /Y "%SLACK_SSB_INTEROP%" "%SLACK_SSB_INTEROP%.mwsbak" >NUL
) ELSE (
	ECHO Backup already exists: %SLACK_SSB_INTEROP%.mwsbak
	PAUSE & EXIT /B 1
)


:: Inject loader code

FOR /F "delims=" %%L IN (%SLACK_SSB_INTEROP%.mwsbak) DO (
	IF "%%L" == "  init(resourcePath, mainModule, !isDevMode);" (
		>>"%SLACK_SSB_INTEROP%" (
			ECHO.  // ** math-with-slack %MWS_VERSION% ** https://github.com/fsavje/math-with-slack
			ECHO.  var mwsp = path.join(__dirname, 'math-with-slack.js'^).replace('app.asar', 'app.asar.unpacked'^);
			ECHO.  require('fs'^).readFile(mwsp, 'utf8', (e, r^) =^> { if (e^) { throw e; } else { eval(r^); } }^);
			ECHO.
			ECHO.  init(resourcePath, mainModule, !isDevMode^);
		)
	) ELSE (
		>>"%SLACK_SSB_INTEROP%" ECHO.%%L
	)
)


:: We're done

ECHO math-with-slack has been installed. Please restart the Slack client.
PAUSE & EXIT /B 0
