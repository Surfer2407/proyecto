$in = 'sample_items.csv'
$out = 'sample_items.tmp'
if (-not (Test-Path $in)) { Write-Error "File not found: $in"; exit 1 }
$rows = Import-Csv $in -Encoding utf8

# Brands to consider
$brands = @('Apple','Samsung','Xiaomi','Poco','OnePlus','Google','Sony','Anker','Belkin','Philips','Dyson','Logitech','Dell','HP','Microsoft','Nike','Adidas','Bosch','Makita')
$brandRegex = ($brands -join '|')
$pattern = [regex]::new("\b(" + $brandRegex + ")\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$fixed = 0
for ($i=0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    $name = $r.name
    if (-not $name) { continue }

    # 1) Normalize 'Model-123' or 'Model_123' or 'Model123' -> remove the Model suffix (keep if model already present earlier)
    $name = $name -replace 'Model[-_]?\d+',''
    $name = $name -replace 'Model\s+\d+',''

    # 2) Remove duplicate adjacent brand tokens e.g. 'Xiaomi Xiaomi 13' -> 'Xiaomi 13'
    foreach ($b in $brands) {
        $dup = "$b\s+" + $b
        $name = [regex]::Replace($name, "(?i)\b" + [regex]::Escape($dup) + "\b", $b)
    }

    # 3) If name contains multiple brands (rare after previous steps), keep first brand and following model-like tokens
    $matches = $pattern.Matches($name) | ForEach-Object { $_.Value } | ForEach-Object { $_.Trim() }
    $distinct = $matches | Select-Object -Unique
    if ($distinct.Count -gt 1) {
        # choose the first brand occurrence
        $primary = $distinct[0]
        # extract whatever follows primary in the string
        $regexAfter = [regex]::new("\b" + [regex]::Escape($primary) + "\b\s*(.+)$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $m = $regexAfter.Match($name)
        if ($m.Success) {
            $candidate = $m.Groups[1].Value -replace '[,\-]',' '
            # remove other brands from candidate
            foreach ($b in $brands) { $candidate = [regex]::Replace($candidate, "(?i)\b" + [regex]::Escape($b) + "\b", '') }
            $candidate = ($candidate -split '\s+') | Where-Object { $_ -ne '' }
            if ($candidate.Count -gt 0) { $model = ($candidate[0..([math]::Min(2,$candidate.Count-1))] -join ' ') } else { $model = '' }
            if ($model -ne '') { $name = "$primary $model" } else { $name = $primary }
        } else {
            $name = $primary
        }
    }

    # 4) Remove repeated brand sequences separated by spaces (non-adjacent) e.g. 'Apple Samsung Xiaomi iPhone 14 Pro' -> keep brand closest to model
    # Already handled above; as fallback remove repeated brand words anywhere keeping first occurrence
    $seen = @{}
    $tokens = $name -split '\s+'
    $outTokens = @()
    foreach ($t in $tokens) {
        $clean = $t -replace '[^A-Za-z0-9]',''
        if ($brands -contains $clean) {
            if ($seen[$clean]) { continue } else { $seen[$clean] = $true }
        }
        $outTokens += $t
    }
    $newName = ($outTokens -join ' ') -replace '\s{2,}',' '
    $newName = $newName.Trim()

    if ($newName -ne $r.name) {
        $r.name = $newName
        $rows[$i] = $r
        $fixed++
    }
}

# Save refined CSV
$rows | Export-Csv -Path $out -NoTypeInformation -Encoding utf8
Move-Item -Force $out $in

# Export CSV with real-named products
$real = Import-Csv $in -Encoding utf8 | Where-Object { $_.name -notmatch '^(Producto|Generic|Basic|Essential|Everyday|Item)\b' }
$real | Export-Csv -Path output\real_named_products.csv -NoTypeInformation -Encoding utf8

# Regenerate outputs
mkdir -Force output
Import-Csv sample_items.csv -Encoding utf8 | ConvertTo-Json -Depth 5 | Set-Content output\products.json -Encoding utf8
Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $cat = ($_.Name -replace '[\\/:*?"<>| ]','_'); $_.Group | Export-Csv -Path ("output\$cat.csv") -NoTypeInformation -Encoding utf8 }
$summary = Import-Csv sample_items.csv -Encoding utf8 | Group-Object category | ForEach-Object { $count = $_.Count; $avg = ($_.Group | Measure-Object -Property price -Average).Average; [PSCustomObject]@{category=$_.Name; count=$count; avg_price=[math]::Round($avg,2)} }
$summary | ConvertTo-Json | Set-Content output\summary.json -Encoding utf8
$summary | Export-Csv output\summary.csv -NoTypeInformation -Encoding utf8

Write-Output "Refined:$fixed RealExported:$($real.Count)"
