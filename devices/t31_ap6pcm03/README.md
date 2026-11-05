# 360 AP6PCM03

A 360-brand PTZ cloud camera on the Ingenic T31X with 128 MB DDR and 32 MB NOR flash.

| Part | Detail |
| --- | --- |
| SoC | Ingenic T31X (Swan board, 128 MB RAM: `mem=64M rmem=64M@0x4000000`) |
| Sensor | GC4653, mounted upside-down (image compensated with mirror+flip) |
| WiFi | ATBM6031 on **MSC1 port A** (PA8-11 + PA16-17, GPIO_FUNC_3), power enable GPIO 53 (active high) |
| Flash | 32 MB NOR, 16 MB partition layout (boot 256k / env 64k / kernel 2M / rootfs 8M / rootfs_data to chip end) |
| IR-cut | GPIO 59 / 60, IR lamp GPIO 14 |
| Speaker | GPIO 63 (amp enable), mic on the internal codec |
| PTZ | 4 shared stepper coils GPIO 49/50/57/58 + H/V select GPIO 62, ULN2803-driven 24BYJ48 motors |
| Button | GPIO 7 (active low) |

## Building

The directory is self-contained: everything the device needs that upstream
firmware lacks travels with it.

```sh
bash builder.sh t31_ap6pcm03            # from the builder repo root
```

What it carries beyond the defconfig:

- `br-ext-chip-ingenic/board/t31/t31.ap6pcm03.config` and
  `patches-ap6pcm03/0001-…` — the MSC1 port-A pin mux (the ATBM6031 hangs on
  port A, while the stock kernel only offers PD/PB/PC, and PB collides with the
  GMAC this camera's Ethernet uses) and the SD card-detect moved from GPIO 59
  (PB27, which the IR-cut needs) to GPIO 61 (PB29);
- `package/ap6pcm03-device` — a local package installed by builder.sh into
  `general/package`: the first-boot customizer, `gpio.conf`, the ATBM power
  calibration files, and the WebUI `ptz-orient.js` post-build patch (the T31
  majestic has no `image.rotate`, which otherwise leaves the PTZ pad dead);
- `general/overlay/etc/wireless/sdio` — a WiFi profile for this camera
  (ATBM6031 on MSC1 port A, power switch on GPIO 53);
- `general/scripts/late-post-build-hooks.list` — registers the WebUI patch.

The same changes also live in a firmware fork
(`a843161264/firmware`) for building the tree directly
(`make BOARD=t31_ap6pcm03`); point `OPENIPC_FW_REPO` at it to build from that
tree instead, as `build-one.yml`'s `firmware_repo` input does.

`.github/workflows/build-ap6pcm03.yml` in this repository builds this device
on demand and uploads the `.tgz` as an artifact.

## Notes from bring-up

- Audio output must run at `srate 16000`: the IMP SDK rejects audio-output
  frames over 20 ms of the channel rate and majestic pushes fixed 640-byte
  frames, which only fit from 16 kHz up.
- Automatic day/night needs `nightMode.lightMonitor true` and a numeric
  `nightMode.autoNightGain` (8 works: daylight idles at ~1.4x gain, darkness
  saturates past 70x, the IR-lit night scene settles near 13x). The
  exposure-based default trigger never fires on this sensor pipeline.
- Local builds should stamp a unique version (`GIT_HASH` at build time, or a
  commit per change): `sysupgrade` silently skips the rootfs write when the
  running and candidate version strings are identical.
- The WebUI's PTZ pad needs `ptz_control=gpio` in the U-Boot environment
  (majestic-webui #227); the customizer sets it.
