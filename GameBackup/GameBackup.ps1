#
# GameBackup.ps1
#

Import-Module PSUserInput
Import-Module .\..\PSScriptUtil.psm1

# global variables
$Global = @{
	'JSONFilePath' = '.\GameBackup.json'
	'BrowserPath'  = "$ProgFiles\Google\Chrome\Application\chrome.exe"
	'FolderURL'    = 'https://drive.google.com/drive/folders/1u-OJ5bVZ0Gaf2Ew-FCCtEtXF74drXao4'
}

$PathVars = @{
	'$HOME'     = $HOME
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
	$BackupPath   = AbsolutePath $BackupPath
	$GameSavePath = AbsolutePath $GameSavePath
	Write-Host "Backing up $GameName @ ($GameSavePath)"

	Write-Host "Checking if backup path ($BackupPath) exists..."
	if (!(Test-Path $BackupPath))
	{
		Write-Host "Creating backup folder ($BackupPath)"
		New-Item -ItemType Directory $BackupPath
	}

	# file name format: GAME.SAVE.zip
	$SaveName   = Split-Path $GameSavePath -leaf
	# removes whitespace from game and save names
	$BackupName = "$($GameName.Replace(' ', '')).$($SaveName.Replace(' ', '')).zip"

	$BackupFilePath = Join-Path $BackupPath $BackupName
	Write-Host "Creating backup @ ($BackupFilePath)"
	Compress-Archive -Force -LiteralPath $GameSavePath -DestinationPath $BackupFilePath
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
