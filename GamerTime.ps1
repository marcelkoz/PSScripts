#
# Gamer Time.ps1
#

Import-Module PSUserInput
Import-Module .\PSScriptUtil.psm1

# application paths
$Discord = "$LocalAppData\Discord\Update.exe"
$Spotify = "$RoamingAppData\Spotify\Spotify.exe"
$Firefox = "$ProgFiles\Mozilla Firefox\firefox.exe"
$Chrome  = "$ProgFiles\Google\Chrome\Application\chrome.exe"

# game launcher paths
$GameLauncher = [ordered]@{
    'Steam'      = "$ProgFilesx86\Steam\Steam.exe"
    'GOG Galaxy' = "$ProgFiles\GOG Galaxy\GalaxyClient.exe"
    'Minecraft'  = "$ProgFilesx86\Minecraft Launcher\MinecraftLauncher.exe"
    'Battle.net' = "$ProgFilesx86\Battle.net\Battle.net Launcher.exe"
    'Xbox'       = "$LocalAppData\Microsoft\WindowsApps\Microsoft.GamingApp_8wekyb3d8bbwe\XboxPcApp.exe"
    'None'       = ''
}

try 
{
    $Games      = $GameLauncher | Select-Object -ExpandProperty Keys
    $Launchers  = Read-MultipleChoiceInput -AcceptList 'What launcher should be run?' $Games
    $RunBrowser = Read-BinaryInput 'Should Chrome be run?'
    $RunOther   = Read-BinaryInput 'Should Discord and Spotify be run?'

    foreach ($Launcher in $Launchers)
    {
        if ($Launcher.Answer -ne 'None')
        {
            Start-Process $GameLauncher[$Launcher.Answer]
        }
    }

    if ($RunBrowser)
    {
        Start-Process $Chrome
    }

    if ($RunOther)
    {
        Start-Process $Discord -ArgumentList '--processStart', 'Discord.exe'
        Start-Process $Spotify
    }
}
catch
{
    $_
    Read-Host 'Press enter to exit'
}
