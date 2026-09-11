# Canon LBP2900 on macOS

Canon does not ship a driver for the LBP2900 that runs on current macOS on Apple Silicon.
This project builds the open-source CAPT driver ([mounaiban/captdriver](https://github.com/mounaiban/captdriver),
a fork of [agalakhov/captdriver](https://github.com/agalakhov/captdriver)) natively for this Mac and installs it into CUPS.

## Requirements

- Xcode command line tools (`clang`), `just` (`brew install just`), `git`.
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
- Upstream is pinned to commit `6271924`; the only macOS tweak is `-D_DARWIN_C_SOURCE` at compile time (upstream's `_POSIX_C_SOURCE` define hides `u_char` in Apple headers).

## Troubleshooting

`just log` turns on CUPS debug logging and tails the driver's lines. `just uninstall` removes everything.
