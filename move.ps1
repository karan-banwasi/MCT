# Source and destination paths

$sourcePath = $PSScriptRoot + "\MetaCompletionTracker"
$destinationPath = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\MetaCompletionTracker"

# Check if the source directory exists
if (-Not (Test-Path -Path $sourcePath)) {
    Write-Output "Source directory does not exist: $sourcePath"
    exit
}

# Ensure the destination directory exists, create it if not
if (-Not (Test-Path -Path $destinationPath)) {
    Write-Output "Destination directory does not exist. Creating it: $destinationPath"
    New-Item -ItemType Directory -Force -Path $destinationPath
}

# Copy the contents from source to destination
Write-Output "Copying files from $sourcePath to $destinationPath..."
Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force

# Confirmation message
Write-Output "Files have been copied successfully!"
