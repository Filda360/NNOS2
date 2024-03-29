# Vytvoření pole nodeModulesArray
$nodeModulesArray = @()

# Získání složek "node_modules" a přidání jejich cest do pole
Get-ChildItem -Path "C:\Users\42060" -Filter node_modules -Directory -Recurse | Where-Object { $_.FullName -notlike "*\node_modules\*" } | ForEach-Object {
    $sizeInBytes = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInMB = [math]::Round($sizeInBytes / 1MB)
    $lastModified = (Get-ChildItem -Path $_.FullName -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    $nodeModulesArray += [PSCustomObject]@{
        Path = $_.FullName
        Size_MB = $sizeInMB
        LastModified = $lastModified
    }
}

# VERZE 1 - graficky okno 
<# $selectedItems = $nodeModulesArray | Out-GridView -Title "Vyberte položky" -OutputMode Multiple #>

# VERZE 2 - CLI (prevzato z: https://github.com/Sebazzz/PSMenu) 
Import-Module .\PSMenu\PSMenu.psm1 -Verbose
Clear-Host
Write-Host "Vyber node_modules k odstranění:"
Write-Host " [MEZERNIK] - vybrat"
Write-Host " [ENTER] - potvrdit výběr"
$selectedItems = Show-Menu -MenuItems $nodeModulesArray -MultiSelect -MenuItemFormatter { $Args | Select -Exp Path }

# Vypsání vybraných položek
Write-Output $selectedItems