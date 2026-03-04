#!/usr/bin/env python3
import csv
import random
import os

IN_FILE = 'sample_items.csv'
TARGET = 10000

r = random.Random(42)
adjs = ['Ultra','Pro','Mini','Smart','Eco','Max','Prime','Flex','Power','Plus','Lite','Compact','Turbo','Premium','Neo','Urban','Home']
nouns = ['Auricular','Cargador','Bolsa','Lámpara','Cafetera','Monitor','Mouse','Teclado','Altavoz','Cámara','Impresora','Bicicleta','Patinete','Sartén','Microondas','Robot','Televisor','SSD','Router','Pulsera','Extractor','Secadora','Hervidor','Plancha','Humidificador','Calefactor','Proyector','Soporte','Kit','Set','Termo','Jarra','Manta','Silla','Mesa']

if not os.path.exists(IN_FILE):
    raise SystemExit(f"File not found: {IN_FILE}")

# Read existing IDs
with open(IN_FILE, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    rows = list(reader)

if len(rows) == 0:
    raise SystemExit('Empty CSV')

header = rows[0]
existing = rows[1:]
existing_count = len(existing)
max_id = 0
for rrow in existing:
    try:
        iid = int(rrow[0])
        if iid > max_id:
            max_id = iid
    except Exception:
        continue

if existing_count >= TARGET:
    print(f"Already has {existing_count} products (>= {TARGET}). No changes made.")
    raise SystemExit(0)

to_add = TARGET - existing_count
start_id = max_id + 1

with open(IN_FILE, 'a', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    for i in range(to_add):
        pid = start_id + i
        name = f"{r.choice(adjs)} {r.choice(nouns)} {pid}"
        price = r.randint(9,499)
        writer.writerow([pid, name, price])

print(f"Appended {to_add} products to {IN_FILE}. Final count: {TARGET} (IDs up to {start_id+to_add-1}).")
