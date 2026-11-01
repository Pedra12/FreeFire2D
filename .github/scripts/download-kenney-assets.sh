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


# Godot 4.3 does not support EXT_meshopt_compression / KHR_mesh_quantization.
# Repack military GLBs as plain glTF-compatible files while keeping rig, names and materials.
TMP_DIR="$(mktemp -d)"
git clone --depth 1 https://github.com/zeux/meshoptimizer.git "$TMP_DIR/meshoptimizer"
cmake -S "$TMP_DIR/meshoptimizer" -B "$TMP_DIR/build" -DMESHOPT_BUILD_GLTFPACK=ON -DCMAKE_BUILD_TYPE=Release
cmake --build "$TMP_DIR/build" --target gltfpack --parallel 2
for model in prototype3d/assets/codelove/*.glb; do
  converted="${model%.glb}.godot.glb"
  "$TMP_DIR/build/gltfpack" -i "$model" -o "$converted" -noq -kn -km -ke
  mv "$converted" "$model"
done
rm -rf "$TMP_DIR"
