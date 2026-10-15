#!/usr/bin/env bash

BASE="Documentation/year"
rm -rf "$BASE"
mkdir -p "$BASE"

declare -A index_by_year

years=$(for f in Documentation/sogs/*; do
    date=$(cut -d'|' -f3 "$f")
    date -d "$date" +%Y
done | sort -u)

{
    echo "Year"
    echo "===="
    echo ""
    echo ".. toctree::"
    echo "  :maxdepth: 2"
    echo "  :caption: Contents:"
    echo ""
    for y in $years; do
        echo "  $y/table"
    done
} > "$BASE/index.rst"

for file in Documentation/sogs/*; do
    [ -f "$file" ] || continue

    group_lines=$(sort -t'|' -k1 -V "$file")

    first_date=$(echo "$group_lines" | head -n1 | cut -d'|' -f3)
    year=$(date -d "$first_date" +%Y)

    outdir="$BASE/$year"
    outfile="$outdir/table.rst"

    mkdir -p "$outdir"

    if [ ! -f "$outfile" ]; then
        {
            echo "Patches ($year)"
            echo "=============="
            echo ""
            echo ".. list-table:: Patches"
            echo "   :header-rows: 1"
            echo ""
            echo "   * - #"
            echo "     - Versão"
            echo "     - Message-ID"
            echo "     - "
        } > "$outfile"
    fi

    ((index_by_year[$year]++))
    idx=${index_by_year[$year]}

    first=1

    for line in $group_lines; do
        version=$(echo "$line" | cut -d'|' -f1)
        refs=$(echo "$line" | cut -d'|' -f2)
        date=$(echo "$line" | cut -d'|' -f3)
        sogs=$(echo "$line" | cut -d'|' -f4)

        msgid=$(echo "$refs" | tr -d '<>')

        if [ $first -eq 1 ]; then
            echo "   * - $idx" >> "$outfile"
        else
            echo "   * - " >> "$outfile"
        fi

        sogs_formatted=$(echo "$sogs" | tr ',' '\n' | sed 's/^/        - /')
        short_id=$(echo "$msgid" | cut -c1-25)

        echo "     - $version" >> "$outfile"
        echo "     - \`$short_id... <https://lore.kernel.org/r/$msgid>\`_" >> "$outfile"

        if [ $first -eq 1 ]; then
            echo "     - Signed-off-by:" >> "$outfile"
            echo "$sogs_formatted" >> "$outfile"
            first=0
        else
            echo "     - " >> "$outfile"
        fi
        
        
    done

done