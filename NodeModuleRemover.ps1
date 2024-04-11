# Define script parameters with aliases for shorthand usage
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

# Install the PSMenu module, which provides functionality for creating interactive menu
Install-Module PSMenu

# Split the input string of excluded directories into an array
$excludeDirectories = $exclude -split ' '

# Display help information if the -h flag is used
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

# If the -f flag is used, set the directory to the home directory of the user
if($full) {
    $Directory = $home
}

# Create an array to store node_modules folders
$nodeModulesArray = @()

# Get all folders named "node_modules" within the specified directory and add it to the array
Get-ChildItem -Path $Directory -Filter $target -Directory -Recurse | Where-Object { $_.FullName -notlike "*\${target}\*" } | ForEach-Object {
    # Exclude directories specified by the user
    if ($_.Parent.Name -in $excludeDirectories) {
        return
    }
    # Exclude hidden directories if the -x flag is used
    if ($_.FullName -like "*\.*" -and $excludeHiddenDirectories -eq $true) {
        return
    }
     # Calculate size and last modified date of each node_modules folder and add it to the array
    $sizeInBytes = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInMB = [math]::Round($sizeInBytes / 1MB)
    $lastModified = (Get-ChildItem -Path $_.FullName -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    $nodeModulesArray += [PSCustomObject]@{
        Path = $_.FullName
        SizeMB = $sizeInMB
        LastModified = $lastModified
    };
}

# Display header
Clear-Host
Write-Host ".------------------------------------------------------------------------------------------------."
Write-Host "| _   _           _      __  __           _       _      ____                                    |"
Write-Host "|| \ | | ___   __| | ___|  \/  | ___   __| |_   _| | ___|  _ \ ___ _ __ ___   _____   _____ _ __ |"
Write-Host "||  \| |/ _ \ / _  |/ _ \ |\/| |/ _ \ / _  | | | | |/ _ \ |_) / _ \ '_   _ \ / _ \ \ / / _ \ '__||"
Write-Host "|| |\  | (_) | (_| |  __/ |  | | (_) | (_| | |_| | |  __/  _ <  __/ | | | | | (_) \ V /  __/ |   |"
Write-Host "||_| \_|\___/ \__,_|\___|_|  |_|\___/ \__,_|\__,_|_|\___|_| \_\___|_| |_| |_|\___/ \_/ \___|_|   |"
Write-Host "'------------------------------------------------------------------------------------------------'"
# Display search information
Write-Host "Folder where we search for node_modules: $($Directory)"
Write-Host "Number of found node_modules folders: $($nodeModulesArray.Count)" -ForegroundColor Blue
Write-Host "Total size of all node_modules folders: $(((($nodeModulesArray | Measure-Object -Property SizeMB -Sum).Sum) / 1000).ToString('0.000')) GB" -ForegroundColor Blue

# If the -da flag is used, delete all node_modules folders
if($deleteAll) {
    Write-Host "Deleting all node_modules folders" -ForegroundColor Yellow
    $nodeModulesArray | ForEach-Object {
        Remove-Item -Path $_.Path -Recurse -Force
        Write-Host "The folder $($_.Path) has been deleted" -ForegroundColor Red
    }
    Exit
}

# If no node_modules folders are found, display a message and exit
if ($nodeModulesArray.Count -eq 0) {
    Write-Host "No node_modules folders found"
    Exit
}
# If node_modules folders are found, prompt the user to select which ones to remove
else {
    # Prompt user to select node_modules folders with custom formatting and multi-select option.
    Write-Host "Select node_modules to remove:" -ForegroundColor Yellow
    Write-Host " [SPACE] - select" -ForegroundColor Yellow
    Write-Host " [ENTER] - confirm all selection" -ForegroundColor Yellow
    $selectedItems = Show-Menu -MenuItems $nodeModulesArray -MultiSelect -ItemFocusColor $FocusColor -MenuItemFormatter { 
        Param($M) $M.Path + " (" + $M.SizeMB + " MB) - " + $M.LastModified
    }
    # Delete selected node_modules folders
    $selectedItems | ForEach-Object {
        Remove-Item -Path $_.Path -Recurse -Force
        Write-Host "The selected folder $($_.Path) has been deleted" -ForegroundColor Red
    }
}


