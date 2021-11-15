#!/bin/bash -Eeu
#
# make.sh - Build the resource pack
#
# Copyright (C) 2021 Rodrigo Silva (MestreLion) <linux@rodrigosilva.com>
# License: GPLv3 or later, at your choice. See <http://www.gnu.org/licenses/gpl>
#------------------------------------------------------------------------------

version=${1:-1.17.1}

#------------------------------------------------------------------------------

mydir=$(dirname "$(readlink -f "$0")")
mcpath=${1:-"$mydir"/../vanilla/"$version"}
source="$mcpath"/src/world/food/Foods.java


# Relevant snippets:
# world/food/Foods.java	Food stats
# public class Foods {
#    public static final FoodProperties CHICKEN = (new FoodProperties.Builder()).nutrition(2).saturationMod(0.3F).effect(new MobEffectInstance(MobEffects.HUNGER, 600, 0), 0.3F).meat().build();
#    public static final FoodProperties BREAD = (new FoodProperties.Builder()).nutrition(5).saturationMod(0.6F).build();
#    public static final FoodProperties RABBIT_STEW = stew(10).build();
#    private static FoodProperties.Builder stew(int nutrition) {
#       return (new FoodProperties.Builder()).nutrition(nutrition).saturationMod(0.6F);
#    }
# }
# world/food/FoodData.java	Nutrition and Saturation assignment
# public void eat(int nutrition, float saturationMod) {
#    this.foodLevel = Math.min(nutrition + this.foodLevel, 20);
#    this.saturationLevel = Math.min(this.saturationLevel + (float)nutrition * saturationMod * 2.0F, (float)this.foodLevel);
#}
# Conclusions (for 1.17.1):
# - Food might have multiple effect(s)
# - nutrition is always followed by saturationMod, first effect always follows saturationMod
# - Stews' saturationMod is hardcoded to 0.6F. Effects for Suspicious Stew are handled elsewhere
# - Cake and Cake slice are handled separately
# - Saturation restored is actually 2 * nutrition * saturationMod
export LC_ALL=C  # Force '.' as decimal separator
stewmod=0.6  # should parse this!
re_effect='\WMobEffects\.([A-Z]+) *, *(\d+) *, *(\d+) *\) *, *([\d.]+)F'
regex='/FoodProperties +([A-Z_]+) *='\
'(?: *stew\((\d+)\))?'\
'(?:.*\.nutrition\((\d+)\))?'\
'(?:.*\.saturationMod\(([\d.]+)F\))?'\
'(?:.*?\.effect\((.+)\))?'\
'/'
parse_food() {
	local source=$1
	local food nutrition satmod effects saturation effects elist
	while read -r food nutrition satmod effects; do
		saturation=$(perl -E "say 2 * ${nutrition} * ${satmod:-$stewmod}")
		elist=$(parse_effects $effects)  # intentionally unquoted
		printf '%-20s\t%2d\t%#4.1f\t%s\n' "${food,,}" "$nutrition" "$saturation" "$elist"
	done < <(perl -nE "$regex"' && do {print "$1\t$2\t$3\t$4\t"; $e = $5;
			while ($e =~ /'"$re_effect"'/g) {print "$1|$2|$3|$4 "}
			print "\n"}' -- "$source")
}
parse_effects() {
	local effects=("$@")
	local effect ticks level odds etitle perc secs
	for effect in "${effects[@]}"; do
		while IFS='|' read -r effect ticks level odds; do
			level=$((level + 1))
			etitle="${effect,,} ${level}"
			perc=$(perl -E "say 100 * ${odds}")
			secs=$((ticks/20))
			printf "%3d%% %3ds %s\t" "$perc" "$secs" "$etitle"
		done <<< "${effect}"
	done
}
parse_food "$source"
