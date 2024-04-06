param (
    [Alias("d")]
    [string]$Directory = (Get-Location)
)                                                                       

# Vytvoření pole nodeModulesArray
$nodeModulesArray = @()

# Získání složek "node_modules" a přidání jejich cest do pole
Get-ChildItem -Path $Directory -Filter node_modules -Directory -Recurse | Where-Object { $_.FullName -notlike "*\node_modules\*" } | ForEach-Object {
    $sizeInBytes = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInMB = [math]::Round($sizeInBytes / 1MB)
    # $lastModified = (Get-ChildItem -Path $_.FullName -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    $nodeModulesArray += [PSCustomObject]@{
        Path = $_.FullName
        SizeMB = $sizeInMB
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
Write-Host "Total size of all node_modules folders: $(((($nodeModulesArray | Measure-Object -Property SizeMB -Sum).Sum) / 1000).ToString('0.00')) GB" -ForegroundColor Blue

if ($nodeModulesArray.Count -eq 0) {
    Write-Host "No node_modules folders found"
    Exit
}
else {
    Write-Host "Select node_modules to remove:" -ForegroundColor Yellow
    Write-Host " [SPACE] - select" -ForegroundColor Yellow
    Write-Host " [ENTER] - confirm all selection" -ForegroundColor Yellow
    $selectedItems = Show-Menu -MenuItems $nodeModulesArray -MultiSelect -MenuItemFormatter { $Args | Select -Exp Path }
    $selectedItems | ForEach-Object {
        Remove-Item -Path $_.Path -Recurse -Force
        Write-Host "The selected folder $($_.Path) has been deleted" -ForegroundColor Red
    }
}


