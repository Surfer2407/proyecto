$in = 'sample_items.csv'
$out = 'sample_items.tmp'
$target = 100

if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$rows = Import-Csv $in -Encoding utf8
$total = $rows.Count

# detect current real-named products
$real = $rows | Where-Object { $_.name -notmatch '^(Producto|Generic|Basic|Essential|Everyday|Item)\b' }
$realCount = $real.Count
$need = $target - $realCount
if ($need -le 0) { Write-Output "Already have $realCount real-named products (>= $target). No changes."; exit 0 }

# Brands/models per category (subset reused)
$brands = @{
    'Electrónica' = @(
        @{brand='Apple'; models=@('iPhone 14 Pro','iPhone 13 Pro','iPad Pro 11','iPad Air 5')},
        @{brand='Samsung'; models=@('Galaxy S23','Galaxy S22','Galaxy Tab S8')},
        @{brand='Xiaomi'; models=@('Xiaomi 13','Xiaomi 12T','Redmi Note 12')},
        @{brand='Poco'; models=@('Poco X5','Poco F4')},
        @{brand='OnePlus'; models=@('OnePlus 11','OnePlus 10 Pro')},
        @{brand='Google'; models=@('Pixel 7','Pixel 6a')}
    )
    'Accesorios' = @(
        @{brand='Anker'; models=@('PowerCore 20000','Wireless Charger Pad')},
        @{brand='Belkin'; models=@('USB-C Hub 7-in-1','BoostCharge Cable')},
        @{brand='Sony'; models=@('WH-CH710N','WF-1000XM4')},
        @{brand='Samsung'; models=@('Galaxy Buds2','Fast Charger')},
        @{brand='Apple'; models=@('AirPods Pro','MagSafe Charger')}
    )
    'Cocina' = @(
        @{brand='Philips'; models=@('Airfryer XXL','SlowJuicer')},
        @{brand='Tefal'; models=@('ActiFry','Easy Fry')},
        @{brand='KitchenAid'; models=@('Artisan Mixer')},
        @{brand='Bosch'; models=@('Horno Serie 4','Licuadora Pro')}
    )
    'Hogar' = @(
        @{brand='IKEA'; models=@('LAMPAN TABLE','BEDSIDE SLAT')},
        @{brand='Philips'; models=@('Hue White Lamp')},
        @{brand='Dyson'; models=@('V8 Vacuum','Pure Cool')},
        @{brand='Xiaomi'; models=@('Mi Smart LED')}
    )
    'Oficina' = @(
        @{brand='Logitech'; models=@('MX Keys','MX Master 3')},
        @{brand='Dell'; models=@('UltraSharp 27','Inspiron 15')},
        @{brand='HP'; models=@('OfficeJet Pro','EliteBook')},
        @{brand='Microsoft'; models=@('Surface Go','Surface Pro')}
    )
    'Deportes' = @(
        @{brand='Nike'; models=@('Running Shoes','Training Shorts')},
        @{brand='Adidas'; models=@('Ultraboost','Tiro Shorts')},
        @{brand='Decathlon'; models=@('Quechua Tent','Kiprun Shoes')}
    )
    'Herramientas' = @(
        @{brand='Bosch'; models=@('Drill PSB 18','Angle Grinder')},
        @{brand='Makita'; models=@('Cordless Drill','Impact Driver')},
        @{brand='Black+Decker'; models=@('Power Drill','Sander')}
    )
    'Jardín' = @(
        @{brand='Gardena'; models=@('Hose Set','Pruning Shears')},
        @{brand='Bosch'; models=@('GardenSub 18','Trimmer')}
    )
    'Moda' = @(
        @{brand='Ray-Ban'; models=@('Sunglasses Classic')},
        @{brand='Nike'; models=@('Sports Socks')},
        @{brand='Zara'; models=@('Leather Bag')}
    )
}

# Price ranges
$priceRanges = @{
    'Electrónica' = @(299,1299)
    'Accesorios' = @(9,199)
    'Cocina' = @(19,499)
    'Hogar' = @(9,399)
    'Oficina' = @(19,599)
    'Deportes' = @(9,599)
    'Herramientas' = @(19,499)
    'Jardín' = @(9,399)
    'Moda' = @(9,299)
}

Get-Random -SetSeed ([int](Get-Date).ToFileTimeUtc() % 10000)

$changed = 0
for ($i=0; $i -lt $rows.Count; $i++) {
    if ($changed -ge $need) { break }
    $row = $rows[$i]
    $name = $row.name
    if ($name -match '^(Producto|Generic|Basic|Essential|Everyday|Item)\b') {
        # decide category to use for branding
        $cat = $row.category
        if (-not $brands.ContainsKey($cat)) {
            # pick a random category that has brands
            $catList = $brands.Keys | Where-Object { $_ -ne 'Otros' }
            $cat = Get-Random -InputObject $catList
            # keep original category in CSV but we'll use chosen cat for brand selection
        }
        $pool = $brands[$cat]
        $choice = Get-Random -InputObject $pool
        $brand = $choice.brand
        $model = Get-Random -InputObject $choice.models
        $variant = "" 
        if ((Get-Random -Minimum 0 -Maximum 10) -lt 4) { $variant = " " + ("Model-" + ([int]$row.id % 1000)) }
        $newName = "$brand $model$variant"
        # price
        if ($priceRanges.ContainsKey($cat)) { $r = $priceRanges[$cat]; $newPrice = Get-Random -Minimum $r[0] -Maximum ($r[1]+1) } else { $newPrice = Get-Random -Minimum 10 -Maximum 500 }
        $row.name = $newName
        $row.price = [string]$newPrice
        $rows[$i] = $row
        $changed++
    }
}

# Save back
$rows | Export-Csv -Path $out -NoTypeInformation -Encoding utf8
Move-Item -Force $out $in
Write-Output "Converted $changed products to brand names (needed $need)."

# regenerate outputs
mkdir -Force output
Import-Csv sample_items.csv -Encoding utf8 | ConvertTo-Json -Depth 5 | Set-Content output\products.json -Encoding utf8
Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $cat = ($_.Name -replace '[\\/:*?"<>| ]','_'); $_.Group | Export-Csv -Path ("output\$cat.csv") -NoTypeInformation -Encoding utf8 }
$summary = Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $count = $_.Count; $avg = ($_.Group | Measure-Object -Property price -Average).Average; [PSCustomObject]@{category=$_.Name; count=$count; avg_price=[math]::Round($avg,2)} }
$summary | ConvertTo-Json | Set-Content output\summary.json -Encoding utf8
$summary | Export-Csv output\summary.csv -NoTypeInformation -Encoding utf8

# report final counts
$csv=Import-Csv sample_items.csv -Encoding utf8
$total=$csv.Count
$real=$csv | Where-Object { $_.name -notmatch '^(Producto|Generic|Basic|Essential|Everyday|Item)\b' } | Measure-Object | Select-Object -ExpandProperty Count
Write-Output "Total:$total`nRealNamed:$real`nPercent:$([math]::Round(($real/$total)*100,2))"