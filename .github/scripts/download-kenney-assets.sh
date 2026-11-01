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
mkdir -p prototype3d/assets/codelove/animations
curl -fL --retry 3 --connect-timeout 20 https://models.codelove.in/animations/m_idle_neutral_01.glb -o prototype3d/assets/codelove/animations/m_idle_neutral_01.glb
curl -fL --retry 3 --connect-timeout 20 https://models.codelove.in/animations/m_walk_neutral_01.glb -o prototype3d/assets/codelove/animations/m_walk_neutral_01.glb
curl -fL --retry 3 --connect-timeout 20 https://models.codelove.in/animations/m_run_neutral_01.glb -o prototype3d/assets/codelove/animations/m_run_neutral_01.glb
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

# CC0 PBR surface maps from ambientCG, mirrored in the FPS Buildings Environment Kit.
PBR_BASE="https://raw.githubusercontent.com/petroulacl/fps-buildings-env-kit/1dd8e932402deb82422920df2e7fd079391e55d3/environment/ground-textures/ambientcg"
fetch_pbr() {
  local pack="$1" prefix="$2"
  local dir="prototype3d/assets/pbr/$pack"
  mkdir -p "$dir"
  for map in Color NormalGL Roughness; do
    curl -fL --retry 3 --connect-timeout 20 "$PBR_BASE/$pack/$prefix-$map.jpg" -o "$dir/$prefix-$map.jpg"
  done
}
fetch_pbr Asphalt021_2K-JPG Asphalt021_2K-JPG
fetch_pbr Grass004_2K-JPG Grass004_2K-JPG
fetch_pbr Concrete012_2K-JPG Concrete012_2K-JPG

# CC0 flat-shaded firearms and real weapon audio from the FPS Asset Kit.
mkdir -p prototype3d/assets/fps/weapons prototype3d/assets/fps/audio
FPS_BASE="https://raw.githubusercontent.com/petroulacl/fps-asset-kit/main"
curl -fL --retry 3 "$FPS_BASE/weapons/flat_guns_west/Flat%20Guns%20West/GLB/Rifle_Assault_West.glb" -o prototype3d/assets/fps/weapons/rifle_assault.glb
curl -fL --retry 3 "$FPS_BASE/weapons/flat_guns_west/Flat%20Guns%20West/GLB/Pistol_Full_West.glb" -o prototype3d/assets/fps/weapons/pistol_full.glb
curl -fL --retry 3 "$FPS_BASE/weapons/flat_guns_west/Flat%20Guns%20West/GLB/Shotgun_Pump_West.glb" -o prototype3d/assets/fps/weapons/shotgun_pump.glb
curl -fL --retry 3 "$FPS_BASE/weapons/flat_guns_west/Flat%20Guns%20West/GLB/SMG_Full_West.glb" -o prototype3d/assets/fps/weapons/smg_full.glb
curl -fL --retry 3 "$FPS_BASE/weapons/flat_guns_west/Flat%20Guns%20West/GLB/Sniper_Rifle_West.glb" -o prototype3d/assets/fps/weapons/sniper_rifle.glb
curl -fL --retry 3 "$FPS_BASE/sfx/footsteps/Fantozzi-footsteps/ogg/Fantozzi-StoneL1.ogg" -o prototype3d/assets/fps/audio/footstep_stone.ogg



# Godot 4.3 does not support EXT_meshopt_compression / KHR_mesh_quantization.
# Repack military GLBs as plain glTF-compatible files while keeping rig, names and materials.
TMP_DIR="$(mktemp -d)"
git clone --depth 1 https://github.com/zeux/meshoptimizer.git "$TMP_DIR/meshoptimizer"
cmake -S "$TMP_DIR/meshoptimizer" -B "$TMP_DIR/build" -DMESHOPT_BUILD_GLTFPACK=ON -DCMAKE_BUILD_TYPE=Release
cmake --build "$TMP_DIR/build" --target gltfpack --parallel 2
while IFS= read -r model; do
  converted="${model%.glb}.godot.glb"
  "$TMP_DIR/build/gltfpack" -i "$model" -o "$converted" -noq -kn -km -ke
  mv "$converted" "$model"
done < <(find prototype3d/assets/codelove -type f -name "*.glb" -print)
rm -rf "$TMP_DIR"

