#
# MCBackup.ps1
#

Import-Module PSUserInput
Import-Module .\PSScriptUtil.psm1

# path variables
$WorldFolder  = "$HOME\AppData\Roaming\.minecraft\saves\Survival"
$BackupFolder = "$HOME\Documents\MCBackup"
$BrowserPath  = "$ProgFiles\Google\Chrome\Application\chrome.exe"

try
{
	$OpenGUI = Read-BinaryInput 'Open google drive after zipping?'

	if (!(Test-Path $WorldFolder))
	{
		Show-Error "The world folder ($WorldFolder) does not exist."
	}

	if (!(Test-Path $BackupFolder))
	{
		Write-Host "Creating backup folder ($BackupFolder)..."
		New-Item -Type Directory $BackupFolder
	}

	$WorldName  = Split-Path -Leaf $WorldFolder
	$BackupPath = Join-Path $BackupFolder "$WorldName.zip"
	Compress-Archive -Force -LiteralPath $WorldFolder -DestinationPath $BackupPath

	Write-Host "Backup created @ ($BackupPath)."

	if ($OpenGUI)
	{
		# open back up folder and google drive
		Invoke-Item $BackupFolder
		Start-Process $BrowserPath -ArgumentList 'https://drive.google.com/drive/folders/1S7zoKe7J16d6ug6nDr91LWSuXVRvuVpv'
	}
}
catch
{
	$_
}
finally
{
	Read-Host 'Press enter to exit'
}
