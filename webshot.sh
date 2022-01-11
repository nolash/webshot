#!/bin/bash

# possible regex for title 
# grep -e "<title>" | sed -e "s/^.*<title>\([^<]*\)<\/title>/\\1/g
# should also convert xml entities, eg. &#8211 -> \u2013 (int -> hex) and render

f=${WEBSHOT_OUTPUT_DIR:-/tmp}
title_parser=${WEBSHOT_TITLE_PARSER} # script that takes contents.txt as input and outputs a single utf8 string
title=$2
>&2 echo using outdir $f

set +e

# prepare 
d=`TZ=UTC date +%Y%m%d%H%M`
t=`mktemp -d`
pushd $t

# store raw outputs
echo $1 > url.txt
curl -s -I $1 > headers.txt
curl -s -X GET $1 > contents.txt
sha256sum contents.txt > contents.txt.sha256

# determine title to use and store it, too
#TODO insert title name protection for mkdir
if [ -z "$title" ]; then
	if [ ! -z "$title_parser" ]; then
		title=`$title_parser contents.txt`
	fi
fi

if [ ! -z "$title" ]; then
	echo $title > title.txt
	>&2 echo using title $title
else
	>&2 echo empty title!
fi


# rendered snapshot
h=`cat contents.txt.sha256 | awk '{ print $1; }'`
chromium --headless --print-to-pdf $1
n=${d}_${h}
mv output.pdf $n.pdf

# store result
mkdir -p "$f/$title"
tar -zcvf "$f/$title/$n.tar.gz" *

# clean up
popd

set -e
