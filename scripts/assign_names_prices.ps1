$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$lines = Get-Content $in -Encoding utf8
$header = $lines[0]
# Define name parts and price ranges per category
$map = @{}
$map['Electrónica'] = @{adjs=@('Ultra','Pro','Smart','Prime','Neo','Max','Advance','X'); nouns=@('TV','Monitor','Router','Altavoz','Cámara','Proyector','SSD','Televisor','Barra de sonido','Pantalla'); range=@(50,800)}
$map['Hogar'] = @{adjs=@('Comfort','Home','Soft','Cozy','Pure','Bright'); nouns=@('Lámpara','Manta','Colchón','Silla','Mesa','Alfombra','Cojín'); range=@(10,400)}
$map['Cocina'] = @{adjs=@('Chef','Kitchen','Gourmet','Easy','Fresh'); nouns=@('Cafetera','Microondas','Licuadora','Sartén','Extractor','Batidora','Hervidor'); range=@(10,350)}
$map['Herramientas'] = @{adjs=@('Power','Pro','Work','Tool'); nouns=@('Taladro','Kit','Atornillador','Compressor'); range=@(20,250)}
$map['Deportes'] = @{adjs=@('Sport','Fit','Active','Pro'); nouns=@('Bicicleta','Patinete','Pesas','Esterilla'); range=@(20,500)}
$map['Jardín'] = @{adjs=@('Garden','Green','Outdoor'); nouns=@('Parrilla','Luz solar','Kit jardinería','Manguera'); range=@(10,300)}
$map['Oficina'] = @{adjs=@('Office','Ergo','Pro','Smart'); nouns=@('Teclado','Mouse','Silla','Monitor','Impresora'); range=@(10,400)}
$map['Accesorios'] = @{adjs=@('Mini','Pocket','Light','Easy'); nouns=@('Cargador','Cable','Funda','Hub','Soporte'); range=@(5,200)}
$map['Moda'] = @{adjs=@('Urban','Style','Classic','Modern'); nouns=@('Gafas','Bolsa','Calcetines','Ropa'); range=@(5,150)}
$map['Belleza'] = @{adjs=@('Glam','Beauty','Silk','Pure'); nouns=@('Secador','Depiladora','Espejo','Set cuidado'); range=@(5,200)}
$map['Otros'] = @{adjs=@('Basic','Everyday','Essential'); nouns=@('Producto','Item'); range=@(10,100)}

# Seed random for reproducibility
Get-Random -SetSeed 12345

$outLines = @()
$outLines += $header
for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    # split into at most 4 parts to preserve commas if any in name (assumes no commas in price or category)
    $parts = $line -split ',',4
    $id = $parts[0]
    $name = if ($parts.Length -ge 2) { $parts[1] } else { "Producto $id" }
    $price = if ($parts.Length -ge 3) { [int]$parts[2] } else { 0 }
    $category = if ($parts.Length -ge 4) { $parts[3] } else { 'Otros' }
    if (-not $map.ContainsKey($category)) { $category = 'Otros' }
    $entryMap = $map[$category]
    # Decide whether to replace name: if generic "Producto <digits>" or name too short
    if ($name -match '^Producto\s+\d+$' -or $name.Length -lt 6) {
        $adj = Get-Random -InputObject $entryMap.adjs
        $noun = Get-Random -InputObject $entryMap.nouns
        $name = "$adj $noun $id"
    }
    # Assign price within category range (integer)
    $min = $entryMap.range[0]; $max = $entryMap.range[1]
    $price = Get-Random -Minimum $min -Maximum ($max + 1)
    $outLines += "$id,$name,$price,$category"
}
$outLines | Set-Content -Path $out -Encoding utf8
Move-Item -Force $out $in
Write-Output "Assigned names and prices for $($outLines.Count - 1) products." 