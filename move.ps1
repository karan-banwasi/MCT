# Source and destination paths

$sourcePath = $PSScriptRoot
$destinationPath = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\MetaCompletionTracker"

# Files to copy
$addonFiles = @(
    "MetaCompletionTracker.toc",
    "Presets.lua",
    "AchievementEngine.lua",
    "MCT.lua"
)

# Ensure destination directory exists, create it if not
if (-Not (Test-Path -Path $destinationPath)) {
    Write-Output "Destination directory does not exist. Creating it: $destinationPath"
    New-Item -ItemType Directory -Force -Path $destinationPath
}

# Copy the addon files to destination
Write-Output "Copying addon files from $sourcePath to $destinationPath..."
foreach ($file in $addonFiles) {
    $filePath = Join-Path $sourcePath $file
    if (Test-Path -Path $filePath) {
        Copy-Item -Path $filePath -Destination $destinationPath -Force
        Write-Output "  Copied: $file"
    } else {
        Write-Warning "  File not found: $filePath"
    }
}

# Confirmation message
Write-Output "Files have been copied successfully!"
