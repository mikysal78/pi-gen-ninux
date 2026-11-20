#!/bin/bash
set -Eeuo pipefail

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# pi-gen deve essere eseguito come root.
if [[ $EUID -ne 0 ]]; then
    exec sudo -- "$BASE_DIR/build-ninux.sh" "$@"
fi

STAGE2_EXPORT="$BASE_DIR/stage2/EXPORT_IMAGE"
NINUX_EXPORT="$BASE_DIR/ninux/EXPORT_IMAGE"
STAGE2_SKIP="$BASE_DIR/stage2/SKIP_IMAGES"

cleanup() {
    rm -f "$NINUX_EXPORT" "$STAGE2_SKIP"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Verifica dei componenti necessari.
for path in \
    "$BASE_DIR/build.sh" \
    "$STAGE2_EXPORT" \
    "$BASE_DIR/stage2" \
    "$BASE_DIR/ninux" \
    "$BASE_DIR/config"
do
    if [[ ! -e "$path" ]]; then
        echo "ERRORE: elemento mancante: $path" >&2
        exit 1
    fi
done

# Non sovrascrivere file eventualmente creati dall'utente.
if [[ -e "$NINUX_EXPORT" || -e "$STAGE2_SKIP" ]]; then
    echo "ERRORE: esistono già file temporanei o personalizzati." >&2
    echo "Controllare:"
    echo "  $NINUX_EXPORT"
    echo "  $STAGE2_SKIP"
    exit 1
fi

# Seleziona lo stage Ninux come sorgente dell'immagine.
cp "$STAGE2_EXPORT" "$NINUX_EXPORT"
touch "$STAGE2_SKIP"

echo "======================================"
echo " Avvio build Raspberry Pi OS Ninux"
echo " Root filesystem: ninux"
echo " Motore: build.sh ufficiale"
echo "======================================"

cd "$BASE_DIR"
"$BASE_DIR/build.sh" "$@"
