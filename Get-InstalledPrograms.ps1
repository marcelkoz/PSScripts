<#
.SYNOPSIS
Get installed software on the local machine. 

.DESCRIPTION
Get installed software on the local machine. Both traditional installer programs and Microsoft Store Appx packages are output with Name, Publisher, Version, Location and Type available to filter. Common queries are shown in the Examples section. The script is also able to dump the output into a json file with the -Path parameter as shown in Examples.

.EXAMPLE
./Get-InstalledPrograms.ps1 -Path installed.json
Dump all installed programs into json file

.EXAMPLE
./Get-InstalledPrograms.ps1 | ConvertTo-Json | Out-File installed.json
Dump all installed programs into json file manually (when filtering output)

.EXAMPLE
./Get-InstalledPrograms.ps1 | where { $_.Type -ne 'Store' }
Filter out Microsoft Store apps

.EXAMPLE
./Get-InstalledPrograms.ps1 | where { $_.Publisher -notlike 'Microsoft*' }
Filter out Microsoft apps

.EXAMPLE
./Get-InstalledPrograms.ps1 | where { $_.Name -like 'Python*' }
View all Python installations

.EXAMPLE
./Get-InstalledPrograms.ps1 | where { $_.Name -like 'Python*' -and $_.Version -like '3.*' }
View all 3.x Python installations

.INPUTS
System.String

.OUTPUTS
Get-InstalledPrograms.Program[]

.LINK
https://github.com/marcelkoz/PSScripts
#>

#
# Get-InstalledPrograms.ps1
#

param (
    [string] $Path = ''
)

$RegistryLocation = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

class Program
{
    [string] $Name
    [string] $Type
    [string] $Version
    [string] $Publisher
    [string] $Location
}

function GetProgramsFromRegistry
{
    $raw = Get-ChildItem $RegistryLocation
    $objects = ($raw | ForEach-Object { Get-ItemProperty $_.PSPath })
    return ConvertRegistryPrograms $objects
}

function ConvertRegistryPrograms($programs)
{
    $converted = New-Object System.Collections.Generic.List[System.Object]
    foreach ($program in $programs)
    {
        $object = [Program]::new()
        $object.Name = (ParseRegistryProgamName $program)
        $object.Type = 'Installer'
        $object.Version = (ParseRegistryVersion $program)
        $object.Publisher = $program.Publisher
        $object.Location = $program.InstallLocation

        $converted.Add($object)
    }
    return $converted.ToArray()
}

function ParseRegistryVersion($program)
{
    $major = $program.VersionMajor
    $minor = $program.VersionMinor
    if ($null -eq $major)
    {
        return ''
    }
    else
    {
        return "$major.$minor"
    }
}

function ParseRegistryProgamName($program)
{
    if ($null -eq $program.DisplayName)
    {
        # use key as program name instead
        return (Split-Path -Leaf $program.PSPath)
    }
    else
    {
        return $program.DisplayName
    }
}

function GetProgramsFromStore
{
    return ConvertStorePrograms (Get-AppxPackage)
}

function ConvertStorePrograms($programs)
{
    $converted = New-Object System.Collections.Generic.List[System.Object]
    foreach ($program in $programs)
    {
        $object = [Program]::new()
        $object.Name = $program.Name
        $object.Type = 'Store'
        $object.Version = $program.Version
        $object.Publisher = (ParseStorePublisherName $program.Publisher)
        $object.Location = $program.InstallLocation

        $converted.Add($object)
    }

    return $converted.ToArray()
}

function ParseStorePublisherName($publisher)
{
    if ($publisher -eq '' -or $null -eq $publisher)
    {
        return ''
    }

    # CN=subdivison, O=publisher/organisation...
    $sections = $publisher.Split(',')
    if ($sections.Length -eq 0)
    {
        return $publisher
    }
    elseif ($sections.Length -eq 1)
    {
        # CN=returned
        return $sections[0].Split('=')[1]
    }
    else
    {
        # CN=..., O=returned
        return $sections[1].Split('=')[1]
    }
}

function StartScript
{
    Write-Host 'NOTE: Run as administrator to view everything.'
    $registry = GetProgramsFromRegistry
    $store = GetProgramsFromStore
    $programs = $registry + $store | Sort-Object -Property Name
    if ($Path -ne '')
    {
        $programs | ConvertTo-Json | Out-File -FilePath $Path
        return
    }

    return $programs
}

return StartScript
