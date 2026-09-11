# Canon LBP2900 on macOS

Canon does not ship a driver for the LBP2900 that runs on current macOS on Apple Silicon.
This project builds the open-source CAPT driver ([mounaiban/captdriver](https://github.com/mounaiban/captdriver),
a fork of [agalakhov/captdriver](https://github.com/agalakhov/captdriver)) natively for this Mac and installs it into CUPS.

## Requirements

- Xcode command line tools (`clang`), `just` (`brew install just`), `git`.
- `askpass.sh` shows the macOS password dialog for `sudo -A`, so the recipes also work from the Claude Code `!` runner, which has no terminal.
- macOS CUPS (built in). No other dependencies.

## Install

```sh
just install   # compile, generate PPD, copy to /Library/Printers (asks for password)
just add       # printer plugged in via USB and powered on
just test      # prints this file
```

## How it works

- `build/rastertocapt` is a CUPS raster filter. macOS converts the job to a raster, the filter converts it to CAPT and talks to the printer through the stock CUPS `usb` backend (status comes back over the CUPS back channel).
- `build/CanonLBP-2900-3000.ppd` is generated from the upstream `canon-lbp.drv` with `ppdc`; the `*cupsFilter` line is rewritten to the absolute install path because `/usr/libexec/cups/filter` is protected by SIP.
- The filter is installed to `/Library/Printers/captdriver/`, the PPD to `/Library/Printers/PPDs/Contents/Resources/`, both owned by root, as CUPS requires.
- Upstream is pinned to commit `6271924` and built with `-D_DARWIN_C_SOURCE` (upstream's `_POSIX_C_SOURCE` define hides `u_char` in Apple headers).
- `lbp2900-macos.patch` is applied on top. It polls the extended status command on every wait (this unit never raises the "extended status changed" flag, so upstream's wait loops hang), initialises the reply size for the job-reserve command, and makes the filter fail with a readable error instead of polling forever when the printer refuses a job or drops the page.

## Troubleshooting

`just log` turns on CUPS debug logging and tails the driver's lines. `just uninstall` removes everything.

The printer keeps job and page state across jobs, so a cancelled, dropped or interrupted job leaves it refusing new work. The driver then stops the job with one of these messages in the print queue window:

- `printer refused the job (code 0x..)`: the printer still holds an old job or is in a stop state. Check paper and the cover, then switch the printer off for 10 seconds and on again, and print again.
- `printer dropped the job (out of paper?)`: the printer accepted the page but never fed paper (an LBP2900 with an empty cassette drops the page silently after about 30 seconds). Load paper, power-cycle, print again.

Paper size sent to the printer is always A4 (upstream reads the raster's media type where the page size name should be). Image dimensions are still right, so Letter prints but may show artefacts.
