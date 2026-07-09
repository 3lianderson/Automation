# 1. The Script Block to be executed remotely
$ScriptBlock = {
    # Suppress the ugly CLIXML progress output over PsExec
    $ProgressPreference = 'SilentlyContinue'
    $ErrorActionPreference = "Continue"

    Write-Output "--- STARTING .NET 6 REMOVAL ---"

    # Step 1: Native Uninstallation via Winget
    Write-Output "[1/2] Attempting uninstallation via Windows Package Manager (Winget)..."
    
    # Locate Winget directly in the system apps directory to bypass path delays
    $AppInstallerPath = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
    $W = Resolve-Path $AppInstallerPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1

    if ($W) {
        Write-Output "      -> Removing .NET Runtime 6..."
        & $W uninstall --id Microsoft.DotNet.Runtime.6 --silent --disable-interactivity --accept-source-agreements 2>&1
        
        Write-Output "      -> Removing .NET AspNetCore 6..."
        & $W uninstall --id Microsoft.DotNet.AspNetCore.6 --silent --disable-interactivity --accept-source-agreements 2>&1
        
        Write-Output "      -> Winget uninstallation tasks completed."
    } else {
        Write-Output "      -> WARNING: Winget not located on host. Proceeding to manual cleanup."
    }

    # Step 2: Clean up Residual Folders
    Write-Output "[2/2] Cleaning up system-level residual .NET 6 directories..."
    
    $PathsToClean = @(
        "C:\Program Files\dotnet\shared\Microsoft.NetCore.App\6.0.*",
        "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\6.0.*",
        "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\6.0.*",
        "C:\Program Files (x86)\dotnet\shared\Microsoft.NetCore.App\6.0.*",
        "C:\Program Files (x86)\dotnet\shared\Microsoft.AspNetCore.App\6.0.*",
        "C:\Program Files (x86)\dotnet\shared\Microsoft.WindowsDesktop.App\6.0.*"
    )

    $FolderFound = $false

    foreach ($Path in $PathsToClean) {
        # Check for directory patterns matching 6.0.x
        $Items = Get-Item -Path $Path -ErrorAction SilentlyContinue
        if ($Items) {
            $FolderFound = $true
            foreach ($Item in $Items) {
                Remove-Item -Path $Item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output "      -> Deleted residual folder: $($Item.FullName)"
            }
        }
    }

    if (-not $FolderFound) {
        Write-Output "      -> No residual .NET 6 folders found."
    }

    Write-Output "--- .NET 6 REMOVAL COMPLETED SUCCESSFULLY ---"
}

# 2. Convert Script Block to Base64 String
$ScriptString = $ScriptBlock.ToString()
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptString)
$EncodedCommand = [Convert]::ToBase64String($Bytes)

# 3. Target Input and Remote Execution via PsExec as SYSTEM (Wrapped in cmd.exe to fix parsing error)
.\PsExec.exe -s \\TargetComputer cmd.exe /c "powershell.exe -NoProfile -EncodedCommand $EncodedCommand"