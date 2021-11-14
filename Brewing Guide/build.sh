#!/bin/bash -Eeu
#
# build.sh - Build from Minecraft language assets
#
# Copyright (C) 2021 Rodrigo Silva (MestreLion) <linux@rodrigosilva.com>
# License: GPLv3 or later, at your choice. See <http://www.gnu.org/licenses/gpl>
#------------------------------------------------------------------------------

version=${1:-1.17.1}

key=container.brewing
langpath=minecraft/lang
right='"§f\ueff1§r"'
left='"§f\ueff2"'

#------------------------------------------------------------------------------

mydir=$(dirname "$(readlink -f "$0")")
mcpath=${mydir}/../vanilla
outdir=${mydir}/assets/${langpath}
default_lang=${mcpath}/assets/

#------------------------------------------------------------------------------

relpath() { python3 -c "import os,sys;print(os.path.relpath(*sys.argv[1:3]))" "$@"; }

index_file() {
	local version=$1
	local index v
	for v in "$version" "${version%.*}"; do
		index=${mcpath}/indexes/${v}.json
		if [[ -f "$index" ]]; then
			echo "$index"
			return
		fi
	done
}

lang_json() {
	local lang=${1##*/}  # strip off 'minecraft/lang/', leaving just 'xx_xx.json'
	local path=$2
	local json
	json=$(jq -ac --arg key "$key" --argjson right "$right" --argjson left "$left" '
		with_entries(select(.key == $key)) |
		map_values(
		    $right + ((24 - 0.75 * length) * " ") +
		    .      + ((24 - 0.75 * length) * " ") + $left)
		' -- "$path"
	)
	if [[ "$json" == '{}' ]]; then
		echo "Key '${key}' not found in language: $lang"
		return
	fi
	echo "Generating language file: ${lang}"
	echo "$json" > "$outdir"/"$lang"
}

#------------------------------------------------------------------------------

index=$(index_file "$version")
echo "Reading master index file for Minecraft ${version}: $(relpath "$index" "$mydir")"
mkdir -p -- "$outdir"

# Default language(s) (currently only en_us)
for lang in "$mcpath"/"$version"/assets/"$langpath"/*.json; do
	lang_json "$lang" "$lang"  # yeah, twice: language/outdir and actual path
done

# Other languages
while read -r lang obj; do
	lang_json "$lang" "$mcpath"/objects/"${obj:0:2}"/"$obj"
done < <(
	jq -r --arg langpath "$langpath" '
		.[] | to_entries | map(select(.key | startswith($langpath + "/")))[]
		| "\(.key)\t\(.value.hash)"
	' -- "$index" | sort
)
