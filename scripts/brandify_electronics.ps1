$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$lines = Get-Content $in -Encoding utf8
$header = $lines[0]

# Brands and models
$brands = @(
    @{name='Apple'; models=@('iPhone 14 Pro','iPhone 13 Pro','iPad Pro 11','iPad Air 5')},
    @{name='Samsung'; models=@('Galaxy S23','Galaxy S22','Galaxy Tab S8')},
    @{name='Xiaomi'; models=@('Xiaomi 13','Xiaomi 12T','Redmi Note 12')},
    @{name='Poco'; models=@('Poco X5','Poco F4','Poco X4 Pro')},
    @{name='OnePlus'; models=@('OnePlus 11','OnePlus 10 Pro')},
    @{name='Google'; models=@('Pixel 7','Pixel 6a')}
)

Get-Random -SetSeed 777

$outLines = @()
$outLines += $header
for ($i=1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $parts = $line -split ',',4
    $id = $parts[0]
    $name = if ($parts.Length -ge 2) { $parts[1] } else { "Producto $id" }
    $price = if ($parts.Length -ge 3) { [int]$parts[2] } else { 0 }
    $category = if ($parts.Length -ge 4) { $parts[3] } else { 'Otros' }

    # Match electronics robustly (handles possible encoding issues like ElectrÃ³nica)
    if ($category -match '(?i)electr') {
        $b = Get-Random -InputObject $brands
        $model = Get-Random -InputObject $b.models
        # add small variant/model code using id
        $variant = "-" + (([int]$id % 100) + 1)
        $name = "$($b.name) $model $variant"
        # price ranges for phones/tablets
        $price = Get-Random -Minimum 299 -Maximum 1299
    }

    $outLines += "$id,$name,$price,$category"
}

$outLines | Set-Content -Path $out -Encoding utf8
Move-Item -Force $out $in
Write-Output "Applied brand-style names to Electrónicos."