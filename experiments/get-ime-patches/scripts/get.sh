#!/usr/bin/env bash

rm -rf Documentation/sogs
mkdir -p Documentation/sogs

lei q '(f:@ime.usp.br+OR+f:@usp.br)' \
    --format=json |
jq -c '
    map({
        messageid: (.m // ""),
        subject: (.s // ""),
        references: (.refs[0] // .m // "") | gsub("[<>]"; ""),
        date: (.dt // "")
    })
    | map(select(.subject | startswith("Re:") | not))
    | unique_by(.messageid)
    | .[]
' |
while read -r msg; do

    messageid=$(echo "$msg" | jq -r '.messageid')
    subject=$(echo "$msg" | jq -r '.subject')
    date=$(echo "$msg" | jq -r '.date')
    references=$(echo "$msg" | jq -r '.references')

    [ -z "$date" ] && continue
    [ "$date" = "null" ] && continue

    version=$(echo "$subject" | grep -oE '\[.*v[0-9]+.*\]' | grep -oE 'v[0-9]+' | head -n1)
    version=${version:-v1}

    vnum=${version#v}

    sogs=$(lei q "m:$messageid" --format=mboxrd |
awk '/^Signed-off-by:/ {
    match($0, /<([^>]+)>/, a)
    if (a[1] != "") print tolower(a[1])
}' | sort -u | paste -sd,)

    group=$(printf "%s" "$sogs" | sha1sum | awk '{print $1}')

    file="Documentation/sogs/${group}.txt"

    if [ ! -f "$file" ]; then
        echo "$version|$references|$date|$sogs" >> "$file"
    else
        grep -q "$references" "$file" && continue
        echo "$version|$references|$date|$sogs" >> "$file"
    fi

done