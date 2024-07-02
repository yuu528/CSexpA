#!/bin/bash

URL="https://www.post.japanpost.jp/zipcode/dl/kogaki-zip.html"
URL_DIR_ESCAPED=$(dirname "$URL" | sed -E 's/([\/\.])/\\\1/g')

DL_DIR="./downloaded_csvs/"


cd $(dirname "$0")
mkdir "$DL_DIR"
cd "$DL_DIR"

# clean
rm *.zip *.CSV *.csv

wget -O - "$URL" |
	grep -Eo 'href="(.+/[0-9]{2}.+\.zip)"' |
	sed -E 's/href="([^"]+)"/'"$URL_DIR_ESCAPED"'\/\1/' |
	xargs -n1 wget

unzip "*.zip"
rm *.zip

# Convert CSVs to UTF-8, Full-width kana and remove unnecessary columns
cat *.CSV |
	nkf -w |
	tr -d \'\"\' |
	cut -d, -f3-9 > all.csv # Output to all.csv
