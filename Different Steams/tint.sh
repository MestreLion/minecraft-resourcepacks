#!/bin/bash -Eeu
#
# tint.sh - Apply tints to Minecraft default Melon and Pumpkin stem assets
#
# Copyright (C) 2021 Rodrigo Silva (MestreLion) <linux@rodrigosilva.com>
# License: GPLv3 or later, at your choice. See <http://www.gnu.org/licenses/gpl>
#------------------------------------------------------------------------------

#https://imagemagick.org/script/color.php
declare -A colors=(
	[melon]='DarkGreen'  # #006400
	[pumpkin]='Orange'   # #FFA500
)
# In-game colors:
# Blocks.ATTACHED_MELON_STEM, Blocks.ATTACHED_PUMPKIN_STEM: 14731036
# Blocks.MELON_STEM, Blocks.PUMPKIN_STEM: {
# 	int i = StemBlock.AGE;
# 	int j = i * 32;
# 	int k = 255 - i * 8;
# 	int l = i * 4;
# 	return j << 16 | k << 8 | l;
# }
# Age from 0 to 7:
#    65280
#  2160388
#  4255496
#  6350604
#  8445712
# 10540820
# 12635928
# 14731036  # Same as Attached color

tint=80  # Percent
assets=assets/minecraft/textures/block

#------------------------------------------------------------------------------

relpath() { python3 -c "import os,sys;print(os.path.relpath(*sys.argv[1:3]))" "$@"; }

mydir=$(dirname "$(readlink -f "$0")")

mcpath=${1:-${mydir}/../vanilla/1.17.1}
outdir=${2:-${mydir}/${assets}}

indir=${mcpath}/${assets}

color() {
	local age=$1
	local r=$((age * 32))
	local g=$((255 - age * 8))
	local b=$((age * 4))
	local i=$((r << 16 | g << 8 | b))
	printf '#%02X%02X%02X\t%8d\t(%3d, %3d, %3d)\n' $r $g $b $i $r $g $b
}

apply_tint() {
	local f=$1
	local d=$2
	local color=$3
	local tint=$4
	out=${d}/${f##*/}
	echo "Applying ${tint}% ${color} to ${f##*/}"
	convert "$f" -colorspace gray -fill "$color" -tint "$tint" "$out" &&
	pngcrush -q -force -blacken -rem "allb" -ow "$out"
}

echo "Reading assets from $(relpath "$mcpath" "$mydir")" \
	"and saving to $(relpath "$outdir" "$mydir")"
mkdir -p -- "$outdir"
for fruit in "${!colors[@]}"; do
	for f in "$indir"/{attached_,}"$fruit"_stem.png; do
		apply_tint "$f" "$outdir" "${colors[$fruit]}" "$tint"
	done
done
