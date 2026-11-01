#!/usr/bin/env bash
set -euo pipefail
BASE="https://raw.githubusercontent.com/Hidencod/tge-assets/main/packs"
OUT="prototype3d/assets/kenney"
fetch() {
  local pack="$1" file="$2"
  mkdir -p "$OUT/$pack"
  curl -fL --retry 3 --connect-timeout 20 "$BASE/$pack/$file" -o "$OUT/$pack/$file"
}
# Kenney CC0 environment assets: https://github.com/Hidencod/tge-assets
# CodeLove military characters: MIT, license embedded in each GLB.
mkdir -p prototype3d/assets/codelove
curl -fL --retry 3 --connect-timeout 20 https://models.codelove.in/models/military-male-02.glb -o prototype3d/assets/codelove/military-male-02.glb
curl -fL --retry 3 --connect-timeout 20 https://models.codelove.in/models/military-male-03.glb -o prototype3d/assets/codelove/military-male-03.glb
curl -fL --retry 3 --connect-timeout 20 https://models.codelove.in/models/military-male-04.glb -o prototype3d/assets/codelove/military-male-04.glb
fetch car-kit suv.glb
fetch car-kit police.glb
fetch car-kit sedan-sports.glb
fetch nature-kit tree-default.glb
fetch nature-kit tree-palm.glb
fetch nature-kit plant-bushlarge.glb
fetch nature-kit rock-largea.glb
fetch city-kit-roads light-curved.glb
fetch city-kit-roads dumpster.glb
fetch city-kit-roads road-sign-street.glb
fetch furniture-kit beddouble.glb
fetch furniture-kit chair.glb
fetch furniture-kit desk.glb
fetch furniture-kit table.glb
fetch furniture-kit cardboardboxclosed.glb
fetch furniture-kit loungesofa.glb

