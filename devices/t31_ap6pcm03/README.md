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

## Requires a firmware fork

The device needs changes that are not in upstream `OpenIPC/firmware`, so build
with `OPENIPC_FW_REPO` pointing at a fork that carries them (see
`build-one.yml`'s `firmware_repo` input for CI):

- kernel patch: MSC1 port-A pin mux (the ATBM6031 hangs on port A, while the
  stock kernel only offers PD/PB/PC — and PB collides with the GMAC this
  camera's Ethernet uses), and the SD card-detect moved from GPIO 59 (PB27,
  which the IR-cut needs) to GPIO 61 (PB29);
- `atbm-wifi` driver (firmware embedded in the module) instead of `atbm60xx`;
- a WiFi profile in `/etc/wireless/sdio` and a WebUI post-build patch for
  `ptz-orient.js` (the T31 majestic has no `image.rotate`, which otherwise
  leaves the PTZ pad dead);
- the `ap6pcm03-device` package carrying the same customizer/gpio.conf this
  directory overlays.

Without the fork the board still builds, but comes up without WiFi, with a
dead PTZ pad and without any device pin configuration.

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
