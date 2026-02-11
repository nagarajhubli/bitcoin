#!/bin/sh

TOPDIR=${TOPDIR:-$(git rev-parse --show-toplevel)}
SRCDIR=${SRCDIR:-$TOPDIR/src}
MANDIR=${MANDIR:-$TOPDIR/doc/man}

BITCOIND=${BITCOIND:-$SRCDIR/bitcoind}
BITCOINCLI=${BITCOINCLI:-$SRCDIR/bitcoin-cli}
BITCOINTX=${BITCOINTX:-$SRCDIR/bitcoin-tx}
BITCOINQT=${BITCOINQT:-$SRCDIR/qt/bitcoin-qt}

cmds=""
first_cmd=""
for cmd in "$BITCOIND" "$BITCOINCLI" "$BITCOINTX" "$BITCOINQT"; do
  if [ -x "$cmd" ]; then
    cmds="$cmds$cmd\n"
    if [ -z "$first_cmd" ]; then
      first_cmd="$cmd"
    fi
  else
    echo "Skipping $cmd: not found or not executable."
  fi
done

[ -z "$first_cmd" ] && echo "No binaries found, nothing to do." && exit 1

# The autodetected version git tag can screw up manpage output a little bit
BTCVERSTR=$("$first_cmd" --version | head -n1 | awk -F'[ -]' '{ print $6 }')
BTCGITSUFFIX=$("$first_cmd" --version | head -n1 | awk -F'[ -]' '{ print $7 }')

# Create a footer file with copyright content.
# This gets autodetected fine for bitcoind if --version-string is not set,
# but has different outcomes for bitcoin-qt and bitcoin-cli.
echo "[COPYRIGHT]" > footer.h2m
"$first_cmd" --version | sed -n '1!p' >> footer.h2m

for cmd in $(printf '%b' "$cmds"); do
  cmdname="${cmd##*/}"
  help2man -N --version-string="$BTCVERSTR" --include=footer.h2m -o "${MANDIR}/${cmdname}.1" "$cmd"
  if [ -n "$BTCGITSUFFIX" ]; then
    sed -i "s/\\\-$BTCGITSUFFIX//g" "${MANDIR}/${cmdname}.1"
  fi
done

rm -f footer.h2m
