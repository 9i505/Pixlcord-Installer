$link = "https://github.com/Vencord/Installer/releases/latest/download/PixlcordInstallerCli.exe"

$outfile = "$env:TEMP\PixlcordInstallerCli.exe"

Write-Output "Downloading installer to $outfile"

Invoke-WebRequest -Uri "$link" -OutFile "$outfile"

Write-Output ""

Start-Process -Wait -NoNewWindow -FilePath "$outfile"

# Cleanup
Remove-Item -Force "$outfile"
