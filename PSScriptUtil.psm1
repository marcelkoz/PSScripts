#
# PSScriptUtil.ps1
#

# path variables
$ProgFiles      = $env:ProgramFiles
$ProgFilesx86   = ${env:ProgramFiles(x86)}
$RoamingAppData = $env:APPDATA
$LocalAppData   = $env:LOCALAPPDATA

function Show-Error($Message)
{
	Write-Error $Message
	Read-Host 'Press enter to exit'
	exit
}

Export-ModuleMember `
	-Variable ProgFiles, ProgFilesx86, RoamingAppData, LocalAppData
