$in='sample_items.csv'; $out='sample_items.tmp'; if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$rows = Import-Csv $in -Encoding utf8
$brandOrder = @('Apple','Samsung','Xiaomi','Poco','OnePlus','Google','Sony','Anker','Belkin','Philips','Dyson','Logitech','Dell','HP','Microsoft','Nike','Adidas','Bosch','Makita')
$models = @{ 'Apple'=@('iPhone 14 Pro','iPhone 13 Pro','iPad Pro 11','iPad Air 5'); 'Samsung'=@('Galaxy S23','Galaxy S22','Galaxy Tab S8'); 'Xiaomi'=@('Xiaomi 13','Xiaomi 12T','Redmi Note 12'); 'Poco'=@('Poco X5','Poco F4'); 'OnePlus'=@('OnePlus 11','OnePlus 10 Pro'); 'Google'=@('Pixel 7','Pixel 6a'); 'Sony'=@('WH-CH710N','WF-1000XM4'); 'Anker'=@('PowerCore 20000','Wireless Charger Pad'); 'Belkin'=@('USB-C Hub 7-in-1','BoostCharge Cable'); 'Philips'=@('Airfryer XXL','Hue White Lamp'); 'Dyson'=@('V8 Vacuum','Pure Cool'); 'Logitech'=@('MX Keys','MX Master 3'); 'Dell'=@('UltraSharp 27','Inspiron 15'); 'HP'=@('OfficeJet Pro','EliteBook'); 'Microsoft'=@('Surface Go','Surface Pro'); 'Nike'=@('Running Shoes','Ultraboost'); 'Adidas'=@('Ultraboost','Tiro Shorts'); 'Bosch'=@('Drill PSB 18','Horno Serie 4'); 'Makita'=@('Cordless Drill','Impact Driver') }
$brandRegex = ($brandOrder -join '|'); $pattern = [regex]::new("\b(" + $brandRegex + ")\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$changed=0; $samples=@()
for ($i=0;$i -lt $rows.Count;$i++){
    $r=$rows[$i]; $name=$r.name; $matches = $pattern.Matches($name) | ForEach-Object { $_.Value } | Select-Object -Unique
    if ($matches.Count -gt 1) {
        # choose primary brand by order
        $primary = $null
        foreach ($b in $brandOrder) { if ($matches -contains $b) { $primary=$b; break } }
        if (-not $primary) { $primary = $matches[0] }
        # pick model from map
        if ($models.ContainsKey($primary)) { $model = (Get-Random -InputObject $models[$primary]) } else { $model = 'Model-' + ([int]$r.id % 1000) }
        $newName = "$primary $model"
        $r.name = $newName
        $rows[$i] = $r
        $changed++
        if ($samples.Count -lt 10) { $samples += [PSCustomObject]@{id=$r.id; old=$name; new=$newName} }
    }
}
$rows | Export-Csv -Path $out -NoTypeInformation -Encoding utf8; Move-Item -Force $out $in
# regenerate outputs
mkdir -Force output; Import-Csv sample_items.csv -Encoding utf8 | ConvertTo-Json -Depth 5 | Set-Content output\products.json -Encoding utf8; Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $cat = ($_.Name -replace '[\\/:*?"<>| ]','_'); $_.Group | Export-Csv -Path ("output\$cat.csv") -NoTypeInformation -Encoding utf8 }
$summary = Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $count = $_.Count; $avg = ($_.Group | Measure-Object -Property price -Average).Average; [PSCustomObject]@{category=$_.Name; count=$count; avg_price=[math]::Round($avg,2)} }
$summary | ConvertTo-Json | Set-Content output\summary.json -Encoding utf8; $summary | Export-Csv output\summary.csv -NoTypeInformation -Encoding utf8
Write-Output "ForcedChanged:$changed"; $samples | ConvertTo-Json -Depth 3
