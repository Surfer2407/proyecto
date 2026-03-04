$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$lines = Get-Content $in -Encoding utf8
$header = $lines[0]

# Brands for accessories
$brands = @(
    @{name='Anker'; models=@('PowerCore 10000','SoundCore 2','Nano Charger')},
    @{name='Belkin'; models=@('BoostCharge 20W','USB-C Hub','Magnetic Stand')},
    @{name='Aukey'; models=@('QuickCharge 3.0','USB Hub','Cable Pro')},
    @{name='Xiaomi'; models=@('Mi Power Bank 3','Mi USB-C Cable','Mi Stand')},
    @{name='Samsung'; models=@('Wireless Charger Pad','USB-C Cable','Fast Charger')}
)

Get-Random -SetSeed 2468
$outLines = @()
$outLines += $header
for ($i=1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $parts = $line -split ',',4
    $id = $parts[0]
    $name = if ($parts.Length -ge 2) { $parts[1] } else { "Producto $id" }
    $price = if ($parts.Length -ge 3) { [int]$parts[2] } else { 0 }
    $category = if ($parts.Length -ge 4) { $parts[3] } else { 'Otros' }

    if ($category -match '(?i)acces') {
        $b = Get-Random -InputObject $brands
        $model = Get-Random -InputObject $b.models
        $variant = "-V" + (([int]$id % 50) + 1)
        $name = "$($b.name) $model $variant"
        $price = Get-Random -Minimum 9 -Maximum 199
    }

    $outLines += "$id,$name,$price,$category"
}

$outLines | Set-Content -Path $out -Encoding utf8
Move-Item -Force $out $in
Write-Output "Applied brand-style names to Accesorios."