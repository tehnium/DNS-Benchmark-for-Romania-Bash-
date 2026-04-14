#!/bin/bash

export LC_NUMERIC=C

CACHE="./wlog-public-dns.html"
URL="https://wlog.ro/public-dns.php"
DOMAIN="etools.ch"
COUNT=10
TOP=12
OUT="./fastest-dns-ro.txt"
BAR_WIDTH=30

# DNS-urile reale publice folosite acum de OpenWrt
CURRENT_PUBLIC_DNS=(
    "109.166.202.230"
    "109.166.202.220"
)

command -v dig >/dev/null 2>&1 || { echo "Lipsește dig. Instalează: sudo apt install dnsutils"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Lipsește curl. Instalează: sudo apt install curl"; exit 1; }

progress_bar() {
    local current=$1
    local total=$2
    local label=$3
    local percent=$(( current * 100 / total ))
    local done=$(( current * BAR_WIDTH / total ))
    local left=$(( BAR_WIDTH - done ))
    local fill empty
    fill=$(printf "%${done}s" "")
    empty=$(printf "%${left}s" "")
    printf "\r[%s%s] %3d%% (%d/%d) %s" "${fill// /#}" "${empty// /-}" "$percent" "$current" "$total" "$label"
}

echo "Downloading/updating DNS list..."
curl -fsSL "$URL" -o "$CACHE" || { echo "Nu am putut descărca lista DNS."; exit 1; }

TMP_ALL=$(mktemp)

grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$CACHE" \
    | awk -F. '$1<=255 && $2<=255 && $3<=255 && $4<=255' \
    | sort -u >> "$TMP_ALL"

printf "%s\n" "${CURRENT_PUBLIC_DNS[@]}" >> "$TMP_ALL"

mapfile -t DNSS < <(sort -u "$TMP_ALL")
rm -f "$TMP_ALL"

TOTAL=${#DNSS[@]}
[[ "$TOTAL" -eq 0 ]] && { echo "Nu am găsit DNS-uri valide."; exit 1; }

echo "=== Testing $TOTAL DNS servers (wlog + current public DNS) ==="

RESULTS_FILE=$(mktemp)
CURRENT=0

for DNS in "${DNSS[@]}"; do
    ((CURRENT++))
    sum_ms=0
    success=0

    for i in $(seq 1 "$COUNT"); do
        qt=$(dig @"$DNS" "$DOMAIN" +stats +time=1 +tries=1 2>/dev/null | awk '/Query time:/ {print $4}')
        if [[ "$qt" =~ ^[0-9]+$ ]]; then
            sum_ms=$((sum_ms + qt))
            ((success++))
        fi
    done

    if [[ "$success" -gt 0 ]]; then
        avg_ms=$((sum_ms / success))
        printf "%s|%s\n" "$avg_ms" "$DNS" >> "$RESULTS_FILE"
        progress_bar "$CURRENT" "$TOTAL" "Testing $DNS avg=${avg_ms}ms"
    else
        progress_bar "$CURRENT" "$TOTAL" "Testing $DNS timeout"
    fi
done

printf "\n"

if [[ ! -s "$RESULTS_FILE" ]]; then
    echo "Niciun DNS nu a răspuns."
    rm -f "$RESULTS_FILE"
    exit 1
fi

sort -t'|' -n "$RESULTS_FILE" > "${RESULTS_FILE}.sorted"
head -n "$TOP" "${RESULTS_FILE}.sorted" > "${RESULTS_FILE}.top"

{
    echo
    echo "============================================================"
    echo "Run date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Source: $URL"
    echo "Domain tested: $DOMAIN"
    echo "Queries per DNS: $COUNT"
    echo

    echo "[Current public DNS used now]"
    for curdns in "${CURRENT_PUBLIC_DNS[@]}"; do
        line=$(grep -F "|$curdns" "${RESULTS_FILE}.sorted" | head -n 1)
        if [[ -n "$line" ]]; then
            avg="${line%%|*}"
            rank=$(awk -F'|' -v dns="$curdns" '$2==dns {print NR}' "${RESULTS_FILE}.sorted")
            echo "$curdns  avg=${avg} ms  rank=${rank}"
        else
            echo "$curdns  avg=timeout  rank=-"
        fi
    done

    echo
    echo "[Top ${TOP} fastest DNS]"
    while IFS='|' read -r avg dns; do
        mark=""
        for curdns in "${CURRENT_PUBLIC_DNS[@]}"; do
            [[ "$dns" == "$curdns" ]] && mark="  CURRENT"
        done
        echo "$dns  avg=${avg} ms${mark}"
    done < "${RESULTS_FILE}.top"

    echo
    echo "[resolv.conf style]"
    while IFS='|' read -r avg dns; do
        echo "# avg=${avg} ms"
        echo "nameserver $dns"
    done < "${RESULTS_FILE}.top"
} >> "$OUT"

echo
echo "=== Appended results to $OUT ==="
tail -n 40 "$OUT"

rm -f "$RESULTS_FILE" "${RESULTS_FILE}.sorted" "${RESULTS_FILE}.top"
