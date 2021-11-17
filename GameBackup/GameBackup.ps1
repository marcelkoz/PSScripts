#
# GameBackup.ps1
#

Import-Module PSUserInput
Import-Module .\..\PSScriptUtil.psm1

# global variables
$Global = @{
	'JSONFilePath' = './GameBackup.json'
	'BrowserPath'  = "$ProgFiles/Google/Chrome/Application/chrome.exe"
	'FolderURL'    = 'https://drive.google.com/drive/folders/1u-OJ5bVZ0Gaf2Ew-FCCtEtXF74drXao4'
}

$PathVars = @{
	'$HOME'     = $HOME
	'$ROAMING'  = $env:APPDATA
	'$PROGS'    = $ProgFiles
	# prevents from '$PROGS' being incorrectly selected
	'$x86PROGS' = $ProgFilesx86
}

# converts a custom object - created by json commands into an easy to use hashtable
function ConvertTo-HashTable($CustomObject)
{
	$properties = $CustomObject.psobject.Properties
	$hash = [ordered]@{}
	$properties | ForEach-Object { $hash[$_.Name] = $_.Value }

	return $hash
}

# converts path with $HOME to be absolute
function AbsolutePath($Path)
{
	$path = $Path.Trim()
	$vars = $PathVars | Select-Object -ExpandProperty Keys
	foreach ($var in $vars)
	{
		if ($path.StartsWith($var))
		{
			$path = Join-Path $($PathVars[$var]) $path.Substring($var.Length)
			break
		}
	}

	return $path
}

# backups a game save
function BackupSave($GameName, $GameSavePath, $BackupPath)
{
	$backupPath   = AbsolutePath $BackupPath
	$gameSavePath = AbsolutePath $GameSavePath
	Write-Host "Backing up $GameName @ ($gameSavePath)"

	Write-Host "Checking if backup path ($backupPath) exists..."
	if (!(Test-Path $backupPath))
	{
		Write-Host "Creating backup folder ($backupPath)"
		New-Item -ItemType Directory $backupPath
	}

	# file name format: GAME.SAVE.zip
	$saveName = Split-Path $gameSavePath -leaf
	# removes whitespace from game and save names
	$backupName = "$($GameName.Replace(' ', '')).$($saveName.Replace(' ', '')).zip"

	$backupFilePath = Join-Path $backupPath $backupName
	Write-Host "Creating backup @ ($backupFilePath)"
	Compress-Archive -Force -LiteralPath $gameSavePath -DestinationPath $backupFilePath
}

function main
{
	$JSON      = Get-Content $Global['JSONFilePath'] | ConvertFrom-Json
	$GameSaves = ConvertTo-HashTable $JSON.GameSaves

	# game to backup
	$BackupGame = Read-MultipleChoiceInput 'What game to backup?' ($GameSaves | Select-Object -ExpandProperty Keys)

	# save to backup
	$Save       = Get-ChildItem -Directory (AbsolutePath $GameSaves[$BackupGame.Answer])
	$BackupSave = Read-MultipleChoiceInput 'What save to backup?' $Save

	BackupSave $BackupGame.Answer $BackupSave.Answer $JSON.BackupPath

	$OpenGUI = Read-BinaryInput 'Open google drive?'
	if ($OpenGUI)
	{
		Invoke-Item (AbsolutePath $JSON.BackupPath)
		Start-Process $Global['BrowserPath'] -ArgumentList $Global['FolderURL']
	}
}


try
{
	main
}
catch
{
	$_
}
finally
{
	Read-Host 'Press enter to exit'
}
