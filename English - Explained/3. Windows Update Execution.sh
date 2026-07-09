# 1. Load the local update script and convert it to a Base64 encoded string
# Reading the raw contents of the script to preserve formatting
$ScriptContent = Get-Content ".\winupdate.ps1" -Raw

# Encoding the script content into a byte array using Unicode (UTF-16LE), which PowerShell requires
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptContent)

# Converting the byte array into a Base64 string for safe command-line execution
$WinUpdateEncoded = [Convert]::ToBase64String($Bytes)

# 2. Execute the encoded payload remotely in memory on the target machine
# Using PsExec to run the command on a remote host (\\TargetMachine) 
# The '-s' flag runs the process under the SYSTEM account.
# The '-NoProfile' flag speeds up execution by not loading the user profile.
# The '-EncodedCommand' flag accepts our Base64 string, preventing syntax/quoting errors.
.\PsExec.exe -s \\TargetMachine powershell -NoProfile -EncodedCommand $WinUpdateEncoded