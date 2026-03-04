# Detect and fix product names that include multiple brand names
$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$rows = Import-Csv $in -Encoding utf8

# Preferred brands order
$brandOrder = @('Apple','Samsung','Xiaomi','Poco','OnePlus','Google','Sony','Anker','Belkin','Philips','Dyson','Logitech','Dell','HP','Microsoft','Nike','Adidas','Bosch','Makita')

# models mapping for fallback
$models = @{
    'Apple'=@('iPhone 14 Pro','iPhone 13 Pro','iPad Pro 11','iPad Air 5')
    'Samsung'=@('Galaxy S23','Galaxy S22','Galaxy Tab S8')
    'Xiaomi'=@('Xiaomi 13','Xiaomi 12T','Redmi Note 12')
    'Poco'=@('Poco X5','Poco F4')
    'OnePlus'=@('OnePlus 11','OnePlus 10 Pro')
    'Google'=@('Pixel 7','Pixel 6a')
    'Sony'=@('WH-CH710N','WF-1000XM4')
    'Anker'=@('PowerCore 20000','Wireless Charger Pad')
    'Belkin'=@('USB-C Hub 7-in-1','BoostCharge Cable')
    'Philips'=@('Airfryer XXL','Hue White Lamp')
    'Dyson'=@('V8 Vacuum','Pure Cool')
    'Logitech'=@('MX Keys','MX Master 3')
    'Dell'=@('UltraSharp 27','Inspiron 15')
    'HP'=@('OfficeJet Pro','EliteBook')
    'Microsoft'=@('Surface Go','Surface Pro')
    'Nike'=@('Running Shoes','Ultraboost')
    'Adidas'=@('Ultraboost','Tiro Shorts')
    'Bosch'=@('Drill PSB 18','Horno Serie 4')
    'Makita'=@('Cordless Drill','Impact Driver')
}

# regex for brands
$brandRegex = ($brandOrder -join '|')
$brandPattern = [regex]::new("\b($brandRegex)\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$changed = 0
$fixedSamples = @()

for ($i=0; $i -lt $rows.Count; $i++) {
    $row = $rows[$i]
    $name = $row.name
    # find distinct brands in name
    $matches = $brandPattern.Matches($name) | ForEach-Object { $_.Value } | ForEach-Object { $_.Trim() }
    $distinct = $matches | Select-Object -Unique
    if ($distinct.Count -gt 1) {
        # select primary brand using preferred order
        $primary = $null
        foreach ($b in $brandOrder) {
            if ($distinct -contains $b) { $primary = $b; break }
        }
        if (-not $primary) { $primary = $distinct[0] }
        # try to extract a model-like token after primary brand in original name
        $model = $null
        $regexAfter = [regex]::new("\b" + [regex]::Escape($primary) + "\b\s*(.+)$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $m = $regexAfter.Match($name)
        if ($m.Success) {
            # take first 5 words as model candidate, strip other brand names
            $candidate = $m.Groups[1].Value -replace "[,\-]"," "
            $words = ($candidate -split '\s+') | Where-Object { $_ -ne '' }
            $filtered = $words | Where-Object { -not ($brandOrder -contains ($_ -replace '[^A-Za-z0-9]','')) }
            if ($filtered.Count -gt 0) {
                $model = ($filtered[0..([math]::Min(2,$filtered.Count-1))] -join ' ')
            }
        }
        if (-not $model -or $model.Length -lt 2) {
            # fallback choose random model for the brand
            if ($models.ContainsKey($primary)) { $model = (Get-Random -InputObject $models[$primary]) } else { $model = "Model-" + ([int]$row.id % 1000) }
        }
        $newName = "$primary $model"
        $row.name = $newName
        $rows[$i] = $row
        $changed++
        if ($fixedSamples.Count -lt 10) { $fixedSamples += [PSCustomObject]@{id=$row.id; old=$name; new=$newName} }
    }
    # normalize category accents
    if ($row.category -match 'Electr') { $row.category = 'Electrónica' }
    if ($row.category -match 'Jard') { $row.category = 'Jardín' }
    $rows[$i] = $row
}

# save
$rows | Export-Csv -Path $out -NoTypeInformation -Encoding utf8
Move-Item -Force $out $in

# regenerate outputs
mkdir -Force output
Import-Csv sample_items.csv -Encoding utf8 | ConvertTo-Json -Depth 5 | Set-Content output\products.json -Encoding utf8
Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $cat = ($_.Name -replace '[\\/:*?"<>| ]','_'); $_.Group | Export-Csv -Path ("output\$cat.csv") -NoTypeInformation -Encoding utf8 }
$summary = Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $count = $_.Count; $avg = ($_.Group | Measure-Object -Property price -Average).Average; [PSCustomObject]@{category=$_.Name; count=$count; avg_price=[math]::Round($avg,2)} }
$summary | ConvertTo-Json | Set-Content output\summary.json -Encoding utf8
$summary | Export-Csv output\summary.csv -NoTypeInformation -Encoding utf8

Write-Output "Fixed:$changed"
$fixedSamples | ConvertTo-Json -Depth 3
