#!/bin/bash
#
[ -e "/home/config/gdrive.json" ] || {
echo "{
    \"ID\": null
}"
}
[ $(cat /home/config/gdrive.json| jq '.ID') == "null"] && exit 1
mkdir -p /home/http/.backup
GDRIVE_FOLDE=$(gdrive mkdir "$(TZ=UTC+3 date +"%d/%m/%Y-%H-%M-%S")" -p $(cat /home/config/gdrive.json| jq '.ID') | sed 's| created||g' | sed 's|Directory ||g')
for a in *
do
    zip --quiet "/home/http/.backup/${a}.zip" -r "${a}"
    gdrive upload "/home/http/.backup/${a}.zip" --parent "$GDRIVE_FOLDE"
    rm -fv "/home/http/.backup/${a}.zip"
done
rm -rfv /home/http/.backup
exit 0