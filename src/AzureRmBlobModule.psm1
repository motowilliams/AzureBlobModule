function Get-AzureBlob {
    [CmdletBinding()]
    param(
        [string]$storageAccountName,
        [string]$containerName,
        [string]$accountKey,
        [string]$blobName,
        [string]$shaMetadataPropertyName = "sha256hash",
        [switch]$IgnoreFailedChecksum
    )
    process {
    
        $connectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$accountKey;EndpointSuffix=core.windows.net"
        $localTargetDirectory = (Get-Location).path
        $context = New-AzureStorageContext -ConnectionString $connectionString
        $localFile = Join-Path $localTargetDirectory $blobName
    
        Write-Verbose "Downloading blob $blobName from container '$containerName' to $localFile"
        $content = Get-AzureStorageBlobContent -Blob $blobName -Container $containerName -Destination $localTargetDirectory -Context $context -Force | Out-Null
    
        if ($IgnoreFailedChecksum) {
            Write-Verbose "Ignoring file hash check"
        }
        else {    
            $blob = Get-AzureStorageBlob -Blob $blobName -Container $containerName -Context $context
            $sha = Get-FileHash $localFile
        
            $remoteFileHash = $blob.ICloudBlob.Metadata.$shaMetadataPropertyName
            if ($remoteFileHash -eq $null) {
                Write-Verbose "Downloaded file does not have a regiested metadata property $shaMetadataPropertyName"
            }
            else {
                Write-Verbose "Downloaded file hash is registered as $shaMetadataPropertyName with a value of $remoteFileHash"
            }
    
            if (($sha.Hash -eq $remoteFileHash) -eq $false) {
                Write-Verbose "Downloaded file has local file hash that does not match recorded sha. Local file hash is $($sha.Hash)"
                Remove-Item $localFile
                Write-Verbose "Removing $localFile"
            }
            else {
                Write-Verbose "Downloaded file has local file hash that matches recorded sha in $containerName"
            }
        }
    
    }
}

function New-AzureBlob {
    [CmdletBinding()]
    param(
        [string]$storageAccountName,
        [string]$containerName,
        [string]$accountKey,
        [parameter(ValueFromPipeline)][string]$filePath,
        [string]$shaMetadataPropertyName = "sha256hash",
        [switch]$IgnoreFailedChecksum
    )
    process {

        $connectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$accountKey;EndpointSuffix=core.windows.net"
        $context = New-AzureStorageContext -ConnectionString $connectionString

        $fileHash = (Get-FileHash $filePath).Hash

        $blobName = (Get-Item $filePath).Name

        Write-Verbose "Uploading file $filePath to container '$containerName' as $blobName"
        Set-AzureStorageBlobContent -File $filePath -Container $ContainerName -Blob $blobName -Context $context -Metadata @{ $shaMetadataPropertyName = $fileHash } -Force

    }
}

Export-ModuleMember -function Get-AzureBlob, New-AzureBlob 