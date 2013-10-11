#!/bin/bash

read -r -d '' colors <<'EOF'
  1564f9
  3fc41b
  fa8e1f
  4ca8ea
  f71347
  fcc124
EOF

for color in ${colors} ; do
  convert -size 128x128 "canvas:#${color}" public/icon_${color}.png
done