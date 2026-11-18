#!/bin/bash
#
# Rebuilds the 32-bit (x86_gcc2h) RenkuOS image for the Sony VAIO P with
# Japanese input, from the checkouts in this directory:
#
#   Renku/          RenkuOS/Source, branch vaio-p-32 (VAIO P patches, the
#                   input_server fix and the image additions committed)
#   buildtools/     haiku/buildtools
#   mozc/           wainohito/mozc, branch renkuos-x86_gcc2h
#   terminalj-plus/ wainohito/terminalj-plus, branch x86_gcc2h
#   vaio-p-packages/ packages the image takes as files (see below)
#
# Output goes to out/. Steps already done are skipped where it is cheap to
# tell (cross-tools, Mozc's host generation).
#
# Needs: what vaiop/build-vaio-p-iso.sh needs, plus tools/bazelisk and the
# host moc of Qt 6 and Qt 5 in tools/hostqt (extracted from the Ubuntu
# qt6-base-dev-tools and qtbase5-dev-tools packages).

set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$TOP/generated.x86_gcc2h"
JOBS="${JOBS:-$(nproc)}"
export PATH="$TOP/buildtools/jam/bin.linuxx86:$PATH"
export HAIKU_IMAGE_LABEL=RenkuOS
log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

jam_image() {
	# A parallel jam sometimes compiles a file before the build package with
	# its headers is extracted (freetype for app_server, zlib for btrfs);
	# jam picks up where it stopped, so try once more.
	(cd "$GEN" && jam -q -j"$JOBS" @nightly-anyboot) \
		|| (cd "$GEN" && jam -q -j"$JOBS" @nightly-anyboot)
}

if [ ! -x "$GEN/cross-tools-x86/bin/i586-pc-haiku-gcc" ]; then
	log "Cross-tools (x86_gcc2 + x86)"
	mkdir -p "$GEN"
	(cd "$GEN" && HOST_AWK="$(command -v gawk)" "$TOP/Renku/configure" \
		--build-cross-tools x86_gcc2 --build-cross-tools x86 \
		--cross-tools-source "$TOP/buildtools" \
		--distro-compatibility default --use-gcc-pipe -j"$JOBS")
fi
[ -x "$TOP/buildtools/jam/bin.linuxx86/jam" ] || make -C "$TOP/buildtools/jam"

# The Japanese packages are built against this tree's libraries, so a fresh
# tree builds the image once without them (DefaultBuildProfiles skips them
# while there is no Mozc package), and again at the end with them.
if [ ! -f "$GEN/haiku-nightly-anyboot.iso" ]; then
	log "RenkuOS (first image, for the libraries the packages link with)"
	jam_image
fi

log "Mozc"
if [ ! -f "$TOP/mozc/src/out_haiku/sources.mk" ]; then
	make -C "$TOP/mozc/src/haiku" gen BAZEL="$TOP/tools/bazelisk"
fi
make -C "$TOP/mozc/src/haiku" ARCH=x86_gcc2h GEN="$GEN" -j"$JOBS" hpkg

log "TerminalJ+"
make -C "$TOP/terminalj-plus" ARCH=x86_gcc2h GEN="$GEN" -j"$JOBS" hpkg

log "Qt 6 and Qt 5 platform plugins"
mkdir -p "$TOP/out"
ARCH=x86_gcc2h GEN="$GEN" MOC="$TOP/tools/hostqt/usr/lib/qt6/libexec/moc" \
	"$TOP/mozc/src/haiku/build/build_qt6_base.sh" "$TOP/qt-work/qt6" "$TOP/out"
ARCH=x86_gcc2h GEN="$GEN" MOC="$TOP/tools/hostqt/usr/lib/qt5/bin/moc" \
	"$TOP/mozc/src/haiku/build/build_qthaikuplugins.sh" "$TOP/qt-work/qt5" "$TOP/out"

log "Packages for the image"
P="$TOP/vaio-p-packages"
mkdir -p "$P/mozc-qt"
cp "$TOP/mozc/src/out_haiku/x86_gcc2h/mozc-3.35.6354-2-x86_gcc2.hpkg" \
	"$TOP/terminalj-plus/build/x86_gcc2/terminalj_plus-1.0.0-1-x86_gcc2.hpkg" "$P/"
cp "$TOP/out/qt6_base_x86-6.10.3.1-1-x86_gcc2.hpkg" \
	"$TOP/out/qthaikuplugins_x86-5.15.16.0.1-1-x86_gcc2.hpkg" "$P/mozc-qt/"
install -m 755 "$TOP/mozc/src/haiku/packaging/bundle/install.sh" "$P/mozc-qt/install"
cp "$TOP/mozc/src/haiku/packaging/bundle/README-Qt.txt" "$P/mozc-qt/README.txt"
# vim_x86 and the WebPositive video packages: see vaiop/build-vaio-p-iso.sh,
# which downloads and checks them.

log "Image"
jam_image
cp "$GEN/haiku-nightly-anyboot.iso" "$TOP/out/renku-vaio-p-ja-x86_gcc2h.iso"
log "Built: $TOP/out/renku-vaio-p-ja-x86_gcc2h.iso"
