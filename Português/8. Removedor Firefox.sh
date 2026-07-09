# 2. The Script Block to be executed remotely
$ScriptBlock = {
    # Suppress the ugly CLIXML progress output over PsExec
    $ProgressPreference = 'SilentlyContinue'
    
    Write-Output "--- STARTING FIREFOX REMOVAL ---"

    # Step 1: Kill running instances
    Write-Output "[1/4] Checking for running Firefox processes..."
    Stop-Process -Name "firefox" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # Step 2: Native Uninstallation
    Write-Output "[2/4] Searching for the Mozilla Firefox uninstaller..."
    $UninstallerPaths = @(
        "${env:ProgramFiles}\Mozilla Firefox\uninstall\helper.exe",
        "${env:ProgramFiles(x86)}\Mozilla Firefox\uninstall\helper.exe"
    )

    $UninstallerFound = $false
    foreach ($Path in $UninstallerPaths) {
        if (Test-Path $Path) {
            Write-Output "      -> Uninstaller found at: $Path"
            Write-Output "      -> Running silent uninstaller..."
            Start-Process -FilePath $Path -ArgumentList "/S" -Wait -NoNewWindow
            $UninstallerFound = $true
        }
    }
    
    if (-not $UninstallerFound) {
        Write-Output "      -> No uninstaller found. Moving to manual cleanup."
    }
    
    Start-Sleep -Seconds 5

    # Step 3: Clean up System Folders
    Write-Output "[3/4] Cleaning up system-level residual folders..."
    $TargetFolders = @(
        "${env:ProgramFiles}\Mozilla Firefox",
        "${env:ProgramFiles(x86)}\Mozilla Firefox",
        "${env:ProgramData}\Mozilla"
    )
    
    foreach ($Folder in $TargetFolders) {
        if (Test-Path $Folder) {
            Remove-Item -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "      -> Deleted: $Folder"
        }
    }

    # Step 4: Clean up User Profiles (AppData)
    Write-Output "[4/4] Cleaning up user profile caches and settings..."
    $UserProfiles = Get-ChildItem "C:\Users" -Directory
    foreach ($Profile in $UserProfiles) {
        $AppDataLocal = Join-Path $Profile.FullName "AppData\Local\Mozilla"
        $AppDataRoaming = Join-Path $Profile.FullName "AppData\Roaming\Mozilla"

        if (Test-Path $AppDataLocal) { 
            Remove-Item -Path $AppDataLocal -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "      -> Deleted Local AppData for user: $($Profile.Name)"
        }
        if (Test-Path $AppDataRoaming) { 
            Remove-Item -Path $AppDataRoaming -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "      -> Deleted Roaming AppData for user: $($Profile.Name)"
        }
    }

    Write-Output "--- FIREFOX REMOVAL COMPLETED SUCCESSFULLY ---"
}

# 3. Convert Script Block to Base64 String
$ScriptString = $ScriptBlock.ToString()
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptString)
$EncodedCommand = [Convert]::ToBase64String($Bytes)

# 4. Remote Execution via PsExec as SYSTEM
.\PsExec.exe -s \\$TargetComputer powershell -NoProfile -EncodedCommand $EncodedCommand