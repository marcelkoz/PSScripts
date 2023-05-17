#
# InstalledProgramsDump.ps1
#

param (
    [string] $Path = ''
)

$RegistryLocation = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

class Program
{
    [string] $Name
    [string] $Publisher
    [string] $Location
}

function GetPrograms
{
    $raw = Get-ChildItem $RegistryLocation
    $objects = ($raw | ForEach-Object { Get-ItemProperty $_.PSPath })
    return FilterProgramProperties $objects
}

function FilterProgramProperties
{
    param (
        $programs
    )

    $filtered = New-Object System.Collections.Generic.List[System.Object]
    foreach ($program in $programs)
    {
        $object = [Program]::new()
        if ($null -eq $program.DisplayName)
        {
            # use key name as program name instead
            $object.Name = (Split-Path -Leaf $program.PSPath)
        }
        else
        {
            $object.Name = $program.DisplayName
        }

        $object.Publisher = $program.Publisher
        $object.Location = $program.InstallLocation

        $filtered.Add($object)
    }
    return $filtered.ToArray()
}

function StartScript {
    $programs = GetPrograms | Sort-Object -Property Name
    if ($Path -ne '')
    {
        $programs | ConvertTo-Json | Out-File -FilePath $Path
        return
    }

    return $programs
}

return StartScript
