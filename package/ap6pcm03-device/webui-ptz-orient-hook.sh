#!/bin/bash
# Two WebUI fixes for this camera, applied to the shipped dist at build time.
#
# 1. The ingenic T31 majestic has no image.rotate: the config.json it serves
#    carries only mirror and flip, and the WebUI's ptz-orient.js refuses that
#    reading ("no orientation"), so the live page's PTZ pad never sends a move
#    -- every press only re-asks /api/v1/config.json. Default a missing quarter
#    turn to 0, which is what a camera without rotate support runs at.
#
# 2. This head's pan motor runs opposite to the picture's turn (the tilt is
#    the axis the shared-coil wiring happens to get right): with the image
#    180-degree compensated (mirror+flip both true) the pad's vertical axis
#    reads correct and the horizontal one inverted. Neutralise the mapping's
#    mirror half so horizontal reads correct too.
set -e
F="${1}/var/www/a/ptz-orient.js"
[ -f "$F" ] || exit 0
python3 - "$F" <<'PYEOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
patched = []
new_s, n = re.subn(r'String\((\w)\.rotate\)', r'void 0===\1.rotate?"0":String(\1.rotate)', s, count=1)
if n:
    s = new_s
    patched.append("missing image.rotate defaults to 0 (T31 majestic has no rotate key)")
new_s, n = re.subn(r'\?null:\{mirror:(\w)\.mirror,flip:', '?null:{mirror:!1,flip:', s, count=1)
if n:
    s = new_s
    patched.append("PTZ pan axis un-mirrored (this head's pan motor is reversed)")
if patched:
    open(p, "w").write(s)
    print("ptz-orient: " + "; ".join(patched))
else:
    print("ptz-orient: no known pattern found, webui layout changed -- patch not applied")
PYEOF
