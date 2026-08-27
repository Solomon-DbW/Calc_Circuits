#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKUP="${ROOT}/../Calc_CPU-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

DRY_RUN=1

if [[ "${1:-}" == "--apply" ]]; then
    DRY_RUN=0
elif [[ "${1:-}" != "" ]]; then
    echo "Usage: $0 [--apply]"
    exit 1
fi

echo "========================================"
echo " Digital / Calc_CPU migration"
echo "========================================"
echo
echo "Project: $ROOT"
echo

if (( DRY_RUN )); then
    echo "MODE: DRY RUN — no files will be moved"
else
    echo "MODE: APPLY — files WILL be moved"
fi

echo

# ------------------------------------------------------------
# Safety checks
# ------------------------------------------------------------

echo "[1/5] Checking for duplicate .dig filenames..."

declare -A seen

while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    key="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

    if [[ -n "${seen[$key]:-}" ]]; then
        echo
        echo "ERROR: Duplicate .dig filename detected:"
        echo "  ${seen[$key]}"
        echo "  $file"
        echo
        echo "Migration aborted."
        echo "Digital requires unique .dig filenames."
        exit 1
    fi

    seen[$key]="$file"
done < <(
    find "$ROOT" \
        -type f \
        -name '*.dig' \
        -print0
)

echo "      OK — no duplicate .dig filenames found."
echo

# ------------------------------------------------------------
# Show current files
# ------------------------------------------------------------

echo "[2/5] Current .dig files:"
echo

find "$ROOT" -maxdepth 1 -type f -name '*.dig' \
    -printf '  %f\n' | sort

echo

# ------------------------------------------------------------
# Directory structure
# ------------------------------------------------------------

echo "[3/5] Planned directory structure:"
echo

DIRS=(
    "01_Arithmetic"
    "02_Multiplexers"
    "03_Demultiplexers_Decoders"
    "04_Latches_FlipFlops"
    "05_Memory"
    "06_Registers"
    "07_ALU"
    "08_Logic"
    "docs"
    "exports"
    "screenshots"
)

for dir in "${DIRS[@]}"; do
    echo "  $dir/"
done

echo

# ------------------------------------------------------------
# Migration map
# ------------------------------------------------------------

declare -A DEST

# Arithmetic
DEST["HALF_ADDER.dig"]="01_Arithmetic"
DEST["FULL_ADDER.dig"]="01_Arithmetic"
DEST["HALF_SUBTRACTOR.dig"]="01_Arithmetic"
DEST["FULL_SUBTRACTOR.dig"]="01_Arithmetic"
DEST["8_BIT_RIPPLE_CARRY_ADDER.dig"]="01_Arithmetic"
DEST["8_BIT_SUBTRACTOR.dig"]="01_Arithmetic"
DEST["8_BIT_ADDER_SUBTRACTOR.dig"]="01_Arithmetic"
DEST["8_BIT_DECREMENTER.dig"]="01_Arithmetic"
DEST["1_BIT_MULTIPLIER.dig"]="01_Arithmetic"
DEST["2_BIT_MULTIPLIER.dig"]="01_Arithmetic"
DEST["8_BIT_MULTIPLIER.dig"]="01_Arithmetic"

# Multiplexers
DEST["2X1_MULTIPLEXER.dig"]="02_Multiplexers"
DEST["2x1_MULTIPLEXER.dig"]="02_Multiplexers"
DEST["4X1_MULTIPLEXER.dig"]="02_Multiplexers"
DEST["8X1_MULTIPLEXER.dig"]="02_Multiplexers"
DEST["1X16_MULTIPLEXER.dig"]="02_Multiplexers"
DEST["16X1_MULTIPLEXER.dig"]="02_Multiplexers"

# Demultiplexers / decoders
DEST["1X2_DEMULTIPLEXER.dig"]="03_Demultiplexers_Decoders"
DEST["1X4_DEMULTIPLEXER.dig"]="03_Demultiplexers_Decoders"
DEST["1X8_DEMULTIPLEXER.dig"]="03_Demultiplexers_Decoders"
DEST["1X16_DEMULTIPLEXER.dig"]="03_Demultiplexers_Decoders"
DEST["1X16_DEMULTIPLEXER_MIRRORED.dig"]="03_Demultiplexers_Decoders"
DEST["3X8_DECODER.dig"]="03_Demultiplexers_Decoders"

# Latches / flip-flops
DEST["SR_NAND.dig"]="04_Latches_FlipFlops"
DEST["SR_NOR.dig"]="04_Latches_FlipFlops"
DEST["SR_LATCH.dig"]="04_Latches_FlipFlops"
DEST["GATED_SR.dig"]="04_Latches_FlipFlops"
DEST["MASTER_SLAVE_JK.dig"]="04_Latches_FlipFlops"

# Memory
DEST["LATCH_MATRIX_UNIT.dig"]="05_Memory"
DEST["ROW_0.dig"]="05_Memory"
DEST["ROW_1.dig"]="05_Memory"
DEST["ROW_2.dig"]="05_Memory"
DEST["ROW_3.dig"]="05_Memory"
DEST["ROW_4.dig"]="05_Memory"
DEST["ROW_5.dig"]="05_Memory"
DEST["ROW_6.dig"]="05_Memory"
DEST["ROW_7.dig"]="05_Memory"

# Keep the main 4x4 / 16x16 / 2048-bit circuits in the project root.
# This allows them to act as entry-point circuits while their
# dependencies remain recursively searchable.
#
# Therefore these are intentionally NOT moved:
#
#   4x4_LATCH_MATRIX.dig
#   4X16_LATCH_MATRIX.dig
#   16x16_LATCH_MATRIX.dig
#   MODULAR_16X16LATCH_MATRIX.dig
#   2048_BIT_MEMORY.dig

# Registers
DEST["8_BIT_REGISTER.dig"]="06_Registers"

# ALU
DEST["LOGIC_UNIT.dig"]="07_ALU"

# Basic logic
DEST["4_BIT_IS_1.dig"]="08_Logic"
DEST["8_BIT_AND.dig"]="08_Logic"
DEST["8_BIT_IS_ZERO.dig"]="08_Logic"

# Documentation
DOCS=(
    "8_BIT_MULTIPLIER.txt"
    "8-bit-subtractor-block-diagram-using-full-adders.png"
)

# Exports
EXPORTS=(
    "4x4_LATCH_MATRIX.svg"
    "16x16_LATCH_MATRIX.svg"
    "16x16_LATCH_MATRIX_fixed.svg"
)

# Screenshots
SCREENSHOTS=(
    "2026-07-26-161052_hyprshot.png"
)

# ------------------------------------------------------------
# Show proposed moves
# ------------------------------------------------------------

echo "[4/5] Proposed .dig moves:"
echo

for file in "${!DEST[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        printf '  %-42s -> %s/\n' "$file" "${DEST[$file]}"
    fi
done | sort

echo

echo "Main entry-point .dig files remaining in root:"
echo

for file in \
    "4x4_LATCH_MATRIX.dig" \
    "4X16_LATCH_MATRIX.dig" \
    "16x16_LATCH_MATRIX.dig" \
    "MODULAR_16X16LATCH_MATRIX.dig" \
    "2048_BIT_MEMORY.dig"
do
    if [[ -f "$ROOT/$file" ]]; then
        echo "  $file"
    fi
done

echo

# ------------------------------------------------------------
# Dry run
# ------------------------------------------------------------

if (( DRY_RUN )); then
    echo "========================================"
    echo " DRY RUN COMPLETE"
    echo "========================================"
    echo
    echo "Nothing has been changed."
    echo
    echo "Review the proposed moves above."
    echo
    echo "If everything looks correct, run:"
    echo
    echo "  ./organise-calc-cpu.sh --apply"
    echo
    exit 0
fi

# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

echo "[5/5] Creating backup..."
echo

tar \
    --exclude='./organise-calc-cpu.sh' \
    -czf "$BACKUP" \
    -C "$ROOT/.." \
    "$(basename "$ROOT")"

echo "Backup created:"
echo "  $BACKUP"
echo

# ------------------------------------------------------------
# Create directories
# ------------------------------------------------------------

for dir in "${DIRS[@]}"; do
    mkdir -p "$ROOT/$dir"
done

# ------------------------------------------------------------
# Move .dig files
# ------------------------------------------------------------

echo "Moving .dig files..."

for file in "${!DEST[@]}"; do
    source="$ROOT/$file"
    destination="$ROOT/${DEST[$file]}/$file"

    if [[ -f "$source" ]]; then
        mv -- "$source" "$destination"
        echo "  $file -> ${DEST[$file]}/"
    fi
done

# ------------------------------------------------------------
# Move documentation
# ------------------------------------------------------------

echo
echo "Moving documentation..."

for file in "${DOCS[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        mv -- "$ROOT/$file" "$ROOT/docs/$file"
        echo "  $file -> docs/"
    fi
done

# ------------------------------------------------------------
# Move exports
# ------------------------------------------------------------

echo
echo "Moving SVG exports..."

for file in "${EXPORTS[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        mv -- "$ROOT/$file" "$ROOT/exports/$file"
        echo "  $file -> exports/"
    fi
done

# ------------------------------------------------------------
# Move screenshots
# ------------------------------------------------------------

echo
echo "Moving screenshots..."

for file in "${SCREENSHOTS[@]}"; do
    if [[ -f "$ROOT/$file" ]]; then
        mv -- "$ROOT/$file" "$ROOT/screenshots/$file"
        echo "  $file -> screenshots/"
    fi
done

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

echo
echo "========================================"
echo " Migration complete"
echo "========================================"
echo

echo "Remaining root .dig files:"
find "$ROOT" -maxdepth 1 -type f -name '*.dig' \
    -printf '  %f\n' | sort

echo
echo "Organised .dig files:"
find "$ROOT" -mindepth 2 -type f -name '*.dig' \
    -printf '  %P\n' | sort

echo
echo "Backup:"
echo "  $BACKUP"
echo
echo "IMPORTANT:"
echo "Open your main Digital circuit from:"
echo "  $ROOT"
echo
echo "Do NOT open a component directory as a separate Digital project."
echo
