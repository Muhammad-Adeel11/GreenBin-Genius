# Kill any lingering Java processes
Stop-Process -Name java -ErrorAction SilentlyContinue

# Define paths
$cPath = "C:\Users\Ghani\.gradle"
$fPath = "F:\.gradle"

# Remove the existing folder on C: (it's mostly empty or corrupted anyway)
if (Test-Path $cPath) {
    Remove-Item -Recurse -Force $cPath
}

# Create the symbolic link (requires no special permissions in most modern Windows setups, but we'll use cmd /c mklink)
cmd /c mklink /D "$cPath" "$fPath"

# Verify link
if (Test-Path $cPath) {
    Write-Host "Successfully linked $cPath to $fPath"
} else {
    Write-Error "Failed to create symbolic link"
    exit 1
}

# Run the build
flutter run
