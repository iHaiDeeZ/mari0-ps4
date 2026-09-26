#!/usr/bin/env bash
#
# Builds a Mari0 PS4 package: zips the game into mari0.love and hands it to the
# LÖVE for PS4 packager (separate repo, see ps4/README.md).
#
#   ps4/build-pkg.sh
#
# Environment:
#   LOVE_PS4        path to the love-ps4 checkout (default: ../love-ps4 next to this repo)
#   LOVE_PS4_BUILD  its build directory (default: love-ps4/build/ps4)
#
# Runs on Linux/WSL with the love-ps4 toolchain installed (love-ps4/platform/ps4/setup-toolchain.sh).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_ROOT="$(cd "$HERE/.." && pwd)"
LOVE_PS4="${LOVE_PS4:-$(cd "$GAME_ROOT/.." && pwd)/love-ps4}"
export LOVE_PS4_BUILD="${LOVE_PS4_BUILD:-$LOVE_PS4/build/ps4}"

if [ ! -x "$LOVE_PS4/platform/ps4/build.sh" ]; then
	echo "error: love-ps4 not found at $LOVE_PS4 (set LOVE_PS4)" >&2
	exit 1
fi

OUT="$GAME_ROOT/build/ps4"
mkdir -p "$OUT"
LOVEFILE="$OUT/mari0.love"
rm -f "$LOVEFILE"

# Same file set as makelove.toml: everything git knows about, minus tooling and non-game folders.
echo "==> packing $LOVEFILE"
(
	cd "$GAME_ROOT"
	git ls-files --cached --others --exclude-standard \
		| grep -v -E '^(_DO_NOT_INCLUDE|ps4|build|\.github)/|^\.' \
		| zip -q -9 "$LOVEFILE" -@
)

# The LÖVE runtime only needs building once; after that just repackage.
if [ ! -f "$LOVE_PS4_BUILD/love/eboot.bin" ]; then
	"$LOVE_PS4/platform/ps4/build.sh" deps
	"$LOVE_PS4/platform/ps4/build.sh" love
fi

LOVE_PS4_GAME="$LOVEFILE" \
LOVE_PS4_TITLE="Mari0 (By ShiroKlein)" \
LOVE_PS4_CONTENT_LABEL="MARI0" \
LOVE_PS4_TITLE_ID="MARI00006" \
LOVE_PS4_VERSION="01.06" \
LOVE_PS4_ICON="$HERE/icon0.png" \
LOVE_PS4_OUT="$OUT" \
	"$LOVE_PS4/platform/ps4/build.sh" pkg
