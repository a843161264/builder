#!/bin/bash
#
# Reports whether this device still lines up with upstream, and what changed in
# the files it mirrors wholesale. Run it before a build after a long gap, or
# when a build fails for no obvious reason.
#
# Usage: bash tools/check-ap6pcm03-upstream.sh [firmware-repo-url]
# Exit:  0 everything still lines up, 1 something needs a look.
set -e

FW_URL="${1:-https://github.com/OpenIPC/firmware.git}"
K_URL="${KERNEL_REPO:-https://github.com/openipc/linux.git}"
K_BRANCH="${KERNEL_BRANCH:-ingenic-t31}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEV="$ROOT/devices/t31_ap6pcm03"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 "$FW_URL" "$TMP/firmware" >/dev/null 2>&1 || {
	echo "cannot clone $FW_URL" >&2; exit 2; }
git clone --depth 1 -b "$K_BRANCH" "$K_URL" "$TMP/linux" >/dev/null 2>&1 || {
	echo "cannot clone $K_URL ($K_BRANCH)" >&2; exit 2; }
FW="$TMP/firmware"
K="$TMP/linux"
status=0
say() { printf '%s\n' "$*"; }

say "== kernel patch =="
if git -C "$K" apply --check "$DEV"/br-ext-chip-ingenic/board/t31/patches-ap6pcm03/*.patch 2>"$TMP/patch.err"; then
	say "  ok: still applies to $K_BRANCH"
else
	say "  NEEDS WORK: no longer applies:"
	sed 's/^/      /' "$TMP/patch.err"
	status=1
fi

say "== kernel config fragment =="
if grep -q 'JZMMC_V12_MMC1_PB_4BIT' "$FW/br-ext-chip-ingenic/board/t31/t31.generic.config"; then
	say "  ok: upstream still sets the port-B default the fragment overrides"
else
	say "  NEEDS WORK: upstream no longer sets CONFIG_JZMMC_V12_MMC1_PB_4BIT"
	status=1
fi

# Lines upstream has that the device copy lacks. The device copy is a superset
# by design; anything only upstream has is a change to merge in.
missing_from() {
	local rel=$1 ours=$2
	if [ ! -f "$FW/$rel" ]; then
		say "  NEEDS WORK: $rel is gone upstream"; status=1; return
	fi
	if cmp -s "$FW/$rel" "$ours"; then
		say "  ok: $rel identical to upstream"; return
	fi
	local missing
	missing=$(comm -23 \
		<(grep -v '^$' "$FW/$rel" | sort -u) \
		<(grep -v '^$' "$ours" | sort -u) | head -20)
	if [ -n "$missing" ]; then
		say "  NEEDS WORK: $rel -- upstream lines the device copy lacks:"
		printf '%s\n' "$missing" | sed 's/^/      /'
		status=1
	else
		say "  ok: $rel -- nothing upstream has is missing"
	fi
}

say "== files mirrored wholesale =="
missing_from general/overlay/etc/wireless/sdio "$DEV/general/overlay/etc/wireless/sdio"
missing_from general/scripts/late-post-build-hooks.list "$DEV/general/scripts/late-post-build-hooks.list"

say "== defconfig versus upstream t31_ultimate =="
up="$FW/br-ext-chip-ingenic/configs/t31_ultimate_defconfig"
ours="$DEV/br-ext-chip-ingenic/configs/t31_ap6pcm03_defconfig"
# Deliberate deltas from the stock ultimate board: the atbm60xx driver is
# replaced by atbm-wifi (firmware embedded), the unused RTL8189FS and MT7601U
# firmware go, and the flash size says 32 (same 16 MB layout, see README).
INTENDED='^(BR2_OPENIPC_FLASH_SIZE|BR2_PACKAGE_ATBM60XX|BR2_PACKAGE_LINUX_FIRMWARE_OPENIPC|BR2_PACKAGE_RTL8189FS_OPENIPC)'
missing=$(comm -23 \
	<(grep '^BR2_' "$up" | grep -vE "$INTENDED" | sort -u) \
	<(grep '^BR2_' "$ours" | sort -u))
if [ -n "$missing" ]; then
	say "  NEEDS WORK: upstream settings the device defconfig lacks (merge the ones that matter):"
	printf '%s\n' "$missing" | sed 's/^/      /'
	status=1
else
	say "  ok: nothing upstream has is missing (beyond the intended deltas)"
fi

say "== packages the device references =="
for p in atbm-wifi gpio-motors reset-button majestic; do
	if [ -d "$FW/general/package/$p" ]; then
		say "  ok: $p"
	else
		say "  NEEDS WORK: $p is gone upstream"; status=1
	fi
done

if [ $status -eq 0 ]; then
	say ""
	say "All clear for this upstream revision."
else
	say ""
	say "Some items above need a look before the next build."
fi
exit $status
