$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$lines = Get-Content $in -Encoding utf8
$header = $lines[0]

# Brands and sample models per category
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
    'Otros' = @(
        @{brand='Generic'; models=@('Item')}
    )
}

# Price ranges per category (min,max)
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
    'Otros' = @(5,199)
}

Get-Random -SetSeed 2026

$outLines = @()
$outLines += $header
for ($i=1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $parts = $line -split ',',4
    $id = $parts[0]
    $name = if ($parts.Length -ge 2) { $parts[1] } else { "Producto $id" }
    $price = if ($parts.Length -ge 3) { [int]$parts[2] } else { 0 }
    $category = if ($parts.Length -ge 4) { $parts[3] } else { 'Otros' }

    # Normalize potential encoding artifacts (ElectrÃ³nica -> Electrónica)
    if ($category -match 'Electr') { $category = 'Electrónica' }
    if (-not $brands.ContainsKey($category)) { $category = 'Otros' }

    # Choose brand and model
    $pool = $brands[$category]
    $choice = Get-Random -InputObject $pool
    $brand = $choice.brand
    $model = Get-Random -InputObject $choice.models

    # Build realistic name: Brand + Model (+ small variant)
    $variant = "" 
    if ((Get-Random -Minimum 0 -Maximum 10) -lt 4) { $variant = " " + ("Model-" + ([int]$id % 1000)) }
    $newName = "$brand $model$variant"

    # Assign price within category range (allowing some variance)
    $range = $priceRanges[$category]
    $min = $range[0]; $max = $range[1]
    $newPrice = Get-Random -Minimum $min -Maximum ($max + 1)

    $outLines += "$id,$newName,$newPrice,$category"
}

$outLines | Set-Content -Path $out -Encoding utf8
Move-Item -Force $out $in
Write-Output "Applied realistic brand names across categories for $($outLines.Count - 1) products."