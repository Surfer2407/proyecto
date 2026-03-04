$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$lines = Get-Content $in -Encoding utf8
$header = $lines[0]

# Category merge map: map old -> new
$merge = @{
    'Belleza' = 'Moda'
    'Moda' = 'Moda'
    'Accesorios' = 'Accesorios'
    'Otros' = 'Otros'
    'Electrónica' = 'Electrónica'
    'Hogar' = 'Hogar'
    'Cocina' = 'Cocina'
    'Herramientas' = 'Herramientas'
    'Deportes' = 'Deportes'
    'Jardín' = 'Jardín'
    'Oficina' = 'Oficina'
}

# Extended keyword mapping to better classify 'Otros'
$kw = @{
    'Electrónica' = 'TV|Televisor|Monitor|Router|SSD|Disco|Impresora|Cámara|Proyector|Altavoz|Auricular|Micrófono|Interfaz|Pantalla|USB|HDMI|LED|Smartwatch|Pulsera|Controlador|Barra de sonido|Estación de carga|Filamento|Reproductor|Pantalla portátil'
    'Hogar' = 'Lámpara|Manta|Colchón|Toallas|Sábanas|Secadora|Perchero|Espejo|Alfombra|Cojín|Cortina|Carrito|Mueble|Mesa|Silla'
    'Cocina' = 'Cafetera|Horno|Microondas|Sartén|Extractor|Batidora|Licuadora|Balanza|Especias|Cubiertos|Plato|Hervidor|Jarra|Tostadora|Cazuela'
    'Herramientas' = 'Taladro|Kit de herramientas|Taladro inalámbrico|Atornillador|Taladro|Kit Arduino|Taladro'
    'Deportes' = 'Bicicleta|Patinete|Pesas|Esterilla|Bicicleta estática|Patinete eléctrico|Calcetines deportivos|Deporte'
    'Jardín' = 'Jardinería|Iluminación solar|Parrilla|Manguera|Jardín|Planta'
    'Oficina' = 'Teclado|Mouse|Impresora|Silla ergonómica|Mesa plegable|Soporte para laptop|Pantalla portátil|Organizador|Reloj despertador|Escritorio'
    'Accesorios' = 'Cargador|Cable|Hub|Adaptador|Funda|Bolsa|Alfombrilla|Soporte TV|Estación de carga|Cargador portátil|Cargador'
    'Moda' = 'Gafas|Calcetines|Bolsa|Ropa|Gafas de sol|Espejo LED maquillaje|Depiladora|Secador|Perfume'
}

# Name templates per (merged) category
$templates = @{
    'Electrónica' = @{adjs=@('Neo','X','Pro','Max','Smart','Ultra','Prime','Edge'); nouns=@('TV','Monitor','Router','Speaker','Camera','Projector','SSD','Display','Soundbar');}
    'Hogar' = @{adjs=@('Cozy','Home','Bright','Comfort','Soft'); nouns=@('Lamp','Blanket','Mattress','Cushion','Lamp-LED','Carpet');}
    'Cocina' = @{adjs=@('Chef','Kitchen','Gourmet','Fresh','Pro'); nouns=@('Coffee','Microwave','Blender','Pan','Juicer');}
    'Herramientas' = @{adjs=@('Power','Pro','Work','Master'); nouns=@('Drill','ToolKit','Driver');}
    'Deportes' = @{adjs=@('Sport','Fit','Active','Pro'); nouns=@('Bike','Scooter','Mat','Weights');}
    'Jardín' = @{adjs=@('Garden','Green','Outdoor'); nouns=@('Grill','SolarLight','GardeningKit');}
    'Oficina' = @{adjs=@('Office','Ergo','Pro'); nouns=@('Keyboard','Mouse','Chair','Monitor');}
    'Accesorios' = @{adjs=@('Pocket','Mini','Lite','Flex'); nouns=@('Charger','Cable','Case','Hub','Stand');}
    'Moda' = @{adjs=@('Urban','Style','Classic','Modern'); nouns=@('Sunglasses','Bag','Socks','Mirror');}
    'Otros' = @{adjs=@('Basic','Everyday','Essential'); nouns=@('Item','Product');}
}

# Seed random
Get-Random -SetSeed 54321

$outLines = @()
$outLines += $header
for ($i=1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $parts = $line -split ',',4
    $id = $parts[0]
    $name = if ($parts.Length -ge 2) { $parts[1] } else { "Producto $id" }
    $price = if ($parts.Length -ge 3) { $parts[2] } else { '0' }
    $category = if ($parts.Length -ge 4) { $parts[3] } else { 'Otros' }

    # Merge category if in merge map
    if ($merge.ContainsKey($category)) { $mcat = $merge[$category] } else { $mcat = $category }

    # Attempt to reclassify if 'Otros' or if name hints at other category
    if ($mcat -eq 'Otros') {
        foreach ($k in $kw.GetEnumerator()) {
            if ($name -match $k.Value) { $mcat = $k.Key; break }
        }
    }

    # Also check name for keywords even if not 'Otros'
    foreach ($k in $kw.GetEnumerator()) {
        if ($name -match $k.Value) { $mcat = $k.Key; break }
    }

    # Normalize merged categories (ensure key exists in templates)
    if (-not $templates.ContainsKey($mcat)) { $mcat = 'Otros' }

    # Decide to replace name if generic or repetitive
    if ($name -match '^(Producto|Basic|Essential|Everyday|Item)\s+\d+$' -or $name -match '^Basic' -or $name.Length -le 8) {
        $t = $templates[$mcat]
        $adj = Get-Random -InputObject $t.adjs
        $noun = Get-Random -InputObject $t.nouns
        # add model suffix from id or random
        $model = "M" + ([int]$id % 1000)
        $name = "$adj $noun $model"
    } else {
        # For non-generic names, append a short model code sometimes to increase variety
        if ((Get-Random -Minimum 0 -Maximum 10) -lt 3) {
            $name = "$name - M" + ([int]$id % 999)
        }
    }

    $outLines += "$id,$name,$price,$mcat"
}

$outLines | Set-Content -Path $out -Encoding utf8
Move-Item -Force $out $in
Write-Output "Updated categories and names for $($outLines.Count - 1) products." 
