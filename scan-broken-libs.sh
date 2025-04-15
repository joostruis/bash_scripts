#!/usr/bin/env bash
#
# scan-broken-libs.sh
#
# Scans system directories for broken or missing shared library dependencies.
#
# Copyright (c) 2025 Joost Ruis <joost.ruis@mocaccino.org>
# License: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Directories to scan (excluding /opt)
DIRS=(
    /bin
    /sbin
    /usr/bin
    /usr/sbin
    /usr/local/bin
    /usr/local/sbin
    /lib
    /lib64
    /usr/lib
    /usr/lib64
    /usr/local/lib
)

# Patterns to ignore — these are known to trigger false positives with ldd
IGNORE_PATTERNS=(
    "libsystemd-core"           # systemd's internal modules, not meant to run standalone
    "libsamba-modules"          # samba plugin libs, dynamically loaded by smbd or similar
    "tracker-miners"            # tracker-miner extract modules, plugin-style
    "/firefox/browser/"         # Firefox plugin/component dirs — loaded via runtime paths
    "/qt*/plugins/"             # Qt plugin folders — not part of core runtime
    "/gstreamer-*/libgst"       # GStreamer plugin modules — optional codec loaders
    "libvirt"                   # virtualization modules loaded by libvirtd/qemu
    "libnss3"                   # NSS may appear missing when scanned directly
    "libnssutil3"               # same as above
    "libsoftokn3"               # crypto module, loaded dynamically
    "/plugins"                  # Generic plugin folders — not directly executable
    "linux-vdso"                # special virtual DSO, not a real file
    "ld-linux"                  # dynamic linker — may show up as missing in indirect scans
)

BROKEN_LIBS=$(mktemp)
SKIPPED_LIBS=$(mktemp)

echo "🔍 Scanning ELF executables for missing libraries..."

for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        find "$dir" -type f -executable -exec file {} + 2>/dev/null | \
        grep -E 'ELF.*(executable|shared object)' | cut -d: -f1 | while read -r bin; do
            [[ -L "$bin" || ! -r "$bin" ]] && continue

            if ldd "$bin" 2>/dev/null | grep -q "not found"; then
                skip=false
                for pattern in "${IGNORE_PATTERNS[@]}"; do
                    if [[ "$bin" == *"$pattern"* ]]; then
                        skip=true
                        break
                    fi
                done

                if $skip; then
                    echo "⚠️  Possibly false positive: $bin"
                    ldd "$bin" 2>/dev/null | grep "not found" >> "$SKIPPED_LIBS"
                else
                    echo "❌ Broken: $bin"
                    ldd "$bin" 2>/dev/null | grep "not found" >> "$BROKEN_LIBS"
                fi
                echo "---"
            fi
        done
    fi
done

# Summary
echo ""
echo "✅ Scan complete."
echo ""
echo "❌ Definitely broken libraries:"
if [[ -s "$BROKEN_LIBS" ]]; then
    sort "$BROKEN_LIBS" | uniq
else
    echo "(none)"
fi

echo ""
echo "⚠️ Possibly false positives (ignored):"
if [[ -s "$SKIPPED_LIBS" ]]; then
    sort "$SKIPPED_LIBS" | uniq
else
    echo "(none)"
fi

rm -f "$BROKEN_LIBS" "$SKIPPED_LIBS"
