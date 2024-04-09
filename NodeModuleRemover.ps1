param (
    [Alias("d")]
    [string]$Directory = (Get-Location),
    [Alias("c")]
    [string]$FocusColor = "Green",
    [Alias("da")]
    [switch]$DeleteAll = $false,
    [Alias("t")]
    [string]$target = "node_modules",
    [Alias("h")]
    [switch]$help = $false,
    [Alias("x")]
    [switch]$excludeHiddenDirectories = $false,
    [Alias("f")]
    [switch]$full = $false,
    [Alias("e")]
    [string]$exclude = ""
)    

Install-Module PSMenu

$excludeDirectories = $exclude -split ' '

if($help) {
    Write-Host "Usage: sem.ps1 [-d <directory>] [-c <color>] [-da] [-t <target>] [-h] [-x] [-f] [-e <exclude>]"
    Write-Host "  -d <directory>  - directory where we search for node_modules (default: current directory)"
    Write-Host "  -c <color>      - color of selected item (default: Green)"
    Write-Host "  -da             - delete all node_modules folders"
    Write-Host "  -t <target>     - target folder name (default: node_modules)"
    Write-Host "  -h              - show help"
    Write-Host "  -x              - exclude hidden directories"
    Write-Host "  -f              - start searching from the home of the user"
    Write-Host "  -e <exclude>    - exclude directories from the search"
    Exit
}

if($full) {
    $Directory = $home
}

# Vytvoření pole nodeModulesArray
$nodeModulesArray = @()

# Získání složek "node_modules" a přidání jejich cest do pole
Get-ChildItem -Path $Directory -Filter $target -Directory -Recurse 
| Where-Object { $_.FullName -notlike "*\${target}\*" } 
| ForEach-Object {
    if ($_.Parent.Name -in $excludeDirectories) {
        return
    }
    if ($_.FullName -like "*\.*" -and $excludeHiddenDirectories -eq $true) {
        return
    }
    $sizeInBytes = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInMB = [math]::Round($sizeInBytes / 1MB)
    $lastModified = (Get-ChildItem -Path $_.FullName -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    $nodeModulesArray += [PSCustomObject]@{
        Path = $_.FullName
        SizeMB = $sizeInMB
        LastModified = $lastModified
    };
}

Clear-Host
Write-Host ".------------------------------------------------------------------------------------------------."
Write-Host "| _   _           _      __  __           _       _      ____                                    |"
Write-Host "|| \ | | ___   __| | ___|  \/  | ___   __| |_   _| | ___|  _ \ ___ _ __ ___   _____   _____ _ __ |"
Write-Host "||  \| |/ _ \ / _  |/ _ \ |\/| |/ _ \ / _  | | | | |/ _ \ |_) / _ \ '_   _ \ / _ \ \ / / _ \ '__||"
Write-Host "|| |\  | (_) | (_| |  __/ |  | | (_) | (_| | |_| | |  __/  _ <  __/ | | | | | (_) \ V /  __/ |   |"
Write-Host "||_| \_|\___/ \__,_|\___|_|  |_|\___/ \__,_|\__,_|_|\___|_| \_\___|_| |_| |_|\___/ \_/ \___|_|   |"
Write-Host "'------------------------------------------------------------------------------------------------'"

Write-Host "Folder where we search for node_modules: $($Directory)"
Write-Host "Number of found node_modules folders: $($nodeModulesArray.Count)" -ForegroundColor Blue
Write-Host "Total size of all node_modules folders: $(((($nodeModulesArray | Measure-Object -Property SizeMB -Sum).Sum) / 1000).ToString('0.000')) GB" -ForegroundColor Blue


if($deleteAll) {
    Write-Host "Deleting all node_modules folders" -ForegroundColor Yellow
    $nodeModulesArray | ForEach-Object {
        Remove-Item -Path $_.Path -Recurse -Force
        Write-Host "The folder $($_.Path) has been deleted" -ForegroundColor Red
    }
    Exit
}

if ($nodeModulesArray.Count -eq 0) {
    Write-Host "No node_modules folders found"
    Exit
}
else {
    Write-Host "Select node_modules to remove:" -ForegroundColor Yellow
    Write-Host " [SPACE] - select" -ForegroundColor Yellow
    Write-Host " [ENTER] - confirm all selection" -ForegroundColor Yellow
    $selectedItems = Show-Menu -MenuItems $nodeModulesArray -MultiSelect -ItemFocusColor $FocusColor -MenuItemFormatter { 
        Param($M) $M.Path + " (" + $M.SizeMB + " MB) - " + $M.LastModified
    }
    $selectedItems | ForEach-Object {
        Remove-Item -Path $_.Path -Recurse -Force
        Write-Host "The selected folder $($_.Path) has been deleted" -ForegroundColor Red
    }
}


