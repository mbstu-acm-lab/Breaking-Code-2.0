@echo off
echo This will reset the hosts file to its default state...

:: Take ownership of the hosts file
takeown /f "%SystemRoot%\System32\drivers\etc\hosts" >nul
icacls "%SystemRoot%\System32\drivers\etc\hosts" /grant "%username%:F" >nul

:: Backup current hosts file (optional)
copy "%SystemRoot%\System32\drivers\etc\hosts" "%SystemRoot%\System32\drivers\etc\hosts.bak" >nul

:: Overwrite hosts file with default content
(
echo # Copyright (c) 1993-2009 Microsoft Corp.
echo #
echo # This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
echo #
echo # This file contains the mappings of IP addresses to host names. Each
echo # entry should be kept on an individual line. The IP address should
echo # be placed in the first column followed by the corresponding host name.
echo # The IP address and the host name should be separated by at least one
echo # space.
echo #
echo # Additionally, comments (such as these) may be inserted on individual
echo # lines or following the machine name denoted by a '#' symbol.
echo #
echo # For example:
echo #
echo #      102.54.94.97     rhino.acme.com          # source server
echo #       38.25.63.10     x.acme.com              # x client host
echo #
echo # localhost name resolution is handled within DNS itself.
echo #       127.0.0.1       localhost
echo #       ::1             localhost
) > "%SystemRoot%\System32\drivers\etc\hosts"

echo Hosts file has been reset to default.
pause
