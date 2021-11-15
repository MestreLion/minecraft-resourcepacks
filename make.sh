#!/bin/bash -Eeu
#
# make.sh - Make all Resource Packs
#
# Copyright (C) 2021 Rodrigo Silva (MestreLion) <linux@rodrigosilva.com>
# License: GPLv3 or later, at your choice. See <http://www.gnu.org/licenses/gpl>
#------------------------------------------------------------------------------

version=${1:-1.17.1}
prefix=ML  # From MestreLion
vanilla=vanilla  # vanilla assets dir
outdir=..  # relative to this

#------------------------------------------------------------------------------

mydir=$(dirname "$(readlink -f "$0")")
assets_root="$mydir"/"$vanilla"
assets_version="$assets_root"/"$version"

#TODO: implement this and use it in packs
export MINECRAFT_HOME="$HOME"/.minecraft
#export MINECRAFT_ASSETS="$MINECRAFT_HOME"/assets
#export MINECRAFT_VERSIONS="$mydir"/"$vanilla"  # extracted from $MINECRAFT_HOME/versions

#------------------------------------------------------------------------------

relpath() { python3 -c "import os,sys;print(os.path.relpath(*sys.argv[1:3]))" "$@"; }

format_from_version() {
	local version=$1
	local num=${version#*.}; num=${num%%.*}
	echo $((num - 10))
}


make_pack() (
	local pack=$1
	local version=$2
	local prefix=$3
	local name="${prefix} ${pack##*/} ${version}"
	local zipfile="$mydir"/"$name".zip
	local format=$(format_from_version "$version")
	echo "Packing $name"
	cd "$pack"
	# Update package format
	sed -Ei '/pack_format/s/:[ \t]*[0-9]*[ \t]*(,?)[ \t]*$/: '"$format"'\1/' pack.mcmeta
	# Compress icon
	pngcrush -q -blacken -rem alla -ow -force pack.png
	rm -f -- "$zipfile"
	zip -qr "$zipfile" -- *
	if [[ "$outdir" && -d "$outdir" ]]; then
		cp -- "$zipfile" "$mydir"/"$outdir"
	fi
)

#------------------------------------------------------------------------------

if ! [[ -d "$assets_root" ]]; then
	echo "Copying Minecraft root assets from ~/.minecraft/assets"
	mkdir -p -- "$assets_root"
	cp -r "$MINECRAFT_HOME"/assets/{objects,indexes} "$assets_root"
	# Removing large Audio files
	while read f; do rm -- "$f"; done < <(
		file "$assets_root"/objects/*/* | grep 'Vorbis audio' | cut -d: -f1
	)
	du -sh "$assets_root"
fi
if ! [[ -d "$assets_version" ]]; then
	echo "Extracting Minecraft ${version} assets JAR"
	mkdir -p -- "$assets_version"
	unzip -qo -d "$assets_version" -- \
		"$MINECRAFT_HOME"/versions/"$version"/"$version".jar 'assets/*' 'data/*'
	du -sh "$assets_version"
fi


echo "Using version ${version}, pack format $(format_from_version "$version")"
for pack in "$mydir"/*; do
	if ! [[ -d "$pack" ]] || [[ "${pack##*/}" == "$vanilla" ]]; then continue; fi
	make_pack "$pack" "$version" "$prefix"
done
