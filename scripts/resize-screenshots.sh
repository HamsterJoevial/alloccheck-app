#!/bin/bash
# resize-screenshots.sh — Redimensionne les captures iPhone 14 Pro Max
# pour App Store Connect (slot 6,5 pouces)
#
# Portrait : 1290x2796 → 1284x2778
# Paysage  : 2796x1290 → 2778x1284
#
# Usage: ./scripts/resize-screenshots.sh [dossier]
#        Par défaut: ./screenshots/

set -euo pipefail

DIR="${1:-./screenshots}"

if [ ! -d "$DIR" ]; then
  echo "❌ Dossier introuvable : $DIR"
  echo "Usage: $0 [dossier_captures]"
  exit 1
fi

COUNT=0
shopt -s nullglob

for file in "$DIR"/*.png "$DIR"/*.PNG "$DIR"/*.jpg "$DIR"/*.JPG "$DIR"/*.jpeg "$DIR"/*.JPEG; do
  [ -f "$file" ] || continue

  W=$(sips -g pixelWidth "$file" | awk '/pixelWidth/{print $2}')
  H=$(sips -g pixelHeight "$file" | awk '/pixelHeight/{print $2}')

  if [ "$W" = "1290" ] && [ "$H" = "2796" ]; then
    echo "📱 Portrait $file → 1284x2778"
    sips --resampleHeightWidth 2778 1284 "$file" --out "$file" >/dev/null
    COUNT=$((COUNT + 1))
  elif [ "$W" = "2796" ] && [ "$H" = "1290" ]; then
    echo "📱 Paysage  $file → 2778x1284"
    sips --resampleHeightWidth 1284 2778 "$file" --out "$file" >/dev/null
    COUNT=$((COUNT + 1))
  else
    echo "⏭️  Ignoré   $file (${W}x${H})"
  fi
done

if [ "$COUNT" -eq 0 ]; then
  echo "Aucune capture 1290x2796 ou 2796x1290 trouvée dans $DIR"
else
  echo "✅ $COUNT capture(s) redimensionnée(s)"
fi
