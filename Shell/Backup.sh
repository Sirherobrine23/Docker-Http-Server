#!/bin/bash
#
cd "/home/http/"
while true
do
#-------------------------------------------------------------------------------------------------
    [ -e "/home/config/gdrive.json" ] || {echo "{\"ID\": null}" > /home/config/gdrive.json}
    [ "$(cat /home/config/gdrive.json| jq '.ID')" == "null"] && exit 1
    mkdir -p /home/http/.backup
    GDRIVE_FOLDE=$(gdrive mkdir "$(TZ=UTC+3 date +"%d/%m/%Y-%H-%M-%S")" -p $(cat /home/config/gdrive.json| jq '.ID') | sed 's| created||g' | sed 's|Directory ||g')
    for a in *
    do
        zip --quiet "/home/http/.backup/${a}.zip" -r "/home/http/${a}"
        gdrive upload "/home/http/.backup/${a}.zip" --parent "$GDRIVE_FOLDE"
        rm -fv "/home/http/.backup/${a}.zip"
    done
    rm -rfv /home/http/.backup
#-------------------------------------------------------------------------------------------------
done
exit 0