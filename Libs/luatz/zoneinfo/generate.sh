#!/bin/bash
cat > "$1.lua" <<EOF
local _, addon = ...
addon.luatz.zoneinfo["$1"] = {
EOF
od --format=u1 --width=1 --output-duplicates --address-radix=n "/usr/share/zoneinfo/$1" | \
sed "s/ //g" | \
sed -z "s/\n/, /g" >> "$1.lua"
echo "}" >> $1.lua
