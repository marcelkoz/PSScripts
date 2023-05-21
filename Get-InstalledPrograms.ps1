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
