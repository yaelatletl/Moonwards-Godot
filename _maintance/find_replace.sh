#!/bin/bash

DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd `
DIR=`dirname $DIR`

SRC=$1
DEST=$2
special=$'.#"'

if [[ -z "$SRC" || -z "$DEST" ]] ; then
    echo "need search string and replacement string"
    exit 0
fi

for ((i=0; i < ${#special}; i++)); do
    char="${special:i:1}"
    SRC="${SRC//"$char"/"\\$char"}"
    DEST="${DEST//"$char"/"\\$char"}"
done

echo "search in" $DIR, replace \"$SRC\" with \"$DEST\"

sed_str="{s#"$SRC"#"$DEST"#g;}"
echo $sed_str
find $DIR \( -iname '*.tscn' -or -iname '*.gd' \) -type f -print0 | xargs -0 grep -l -z $1 | xargs sed -i -e "$sed_str"
