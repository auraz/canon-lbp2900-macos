# Build and install the open-source CAPT driver (rastertocapt) for a Canon LBP2900 on macOS.

repo := "https://github.com/mounaiban/captdriver.git"
rev := "6271924"
src := "captdriver"
filter_dir := "/Library/Printers/captdriver"
ppd_dir := "/Library/Printers/PPDs/Contents/Resources"
ppd := "CanonLBP-2900-3000.ppd"
name := "Canon_LBP2900"

export SUDO_ASKPASS := justfile_directory() / "askpass.sh"

default: build

# Clone the pinned upstream source and apply the LBP2900 status-polling fix.
clone:
    [ -d {{src}} ] || git clone -q {{repo}} {{src}}
    git -C {{src}} checkout -q {{rev}} && git -C {{src}} checkout -q -- . && git -C {{src}} apply {{justfile_directory()}}/lbp2900-macos.patch

# Compile the CUPS filter for this Mac and generate the PPD.
build: clone
    mkdir -p build
    clang -std=c99 -O2 -Wall -Wno-deprecated-declarations -D_DARWIN_C_SOURCE -o build/rastertocapt {{src}}/src/*.c -lcups -lcupsimage
    LC_ALL=C ppdc -d build {{src}}/src/canon-lbp.drv
    sed -i '' 's|1 rastertocapt"|1 {{filter_dir}}/rastertocapt"|' build/{{ppd}}
    cupstestppd -W filters -W sizes build/{{ppd}}

# Install the filter and PPD system-wide (asks for your password).
install: build
    sudo -A install -d -o root -g wheel -m 755 {{filter_dir}}
    sudo -A install -o root -g wheel -m 755 build/rastertocapt {{filter_dir}}/
    sudo -A install -o root -g wheel -m 644 build/{{ppd}} {{ppd_dir}}/
    cupstestppd -W sizes {{ppd_dir}}/{{ppd}}

# Add the USB printer to CUPS. Plug in and power on the printer first.
add:
    #!/usr/bin/env bash
    set -euo pipefail
    uri=$(lpinfo -v | awk '/usb:.*LBP2900/ {print $2; exit}')
    [ -n "$uri" ] || { echo "LBP2900 not found on USB. Check cable and power, then retry."; exit 1; }
    sudo -A lpadmin -p {{name}} -E -v "$uri" -P {{ppd_dir}}/{{ppd}} -o printer-is-shared=false
    lpstat -p {{name}}

# Print this README as a test page.
test:
    lp -d {{name}} README.md

# Show live CUPS log lines from the driver (Ctrl-C to stop).
log:
    sudo -A cupsctl --debug-logging
    tail -f /private/var/log/cups/error_log | grep -i -E 'capt|usb|rastertocapt'

# Remove the printer, filter and PPD.
uninstall:
    -sudo -A lpadmin -x {{name}}
    sudo -A rm -rf {{filter_dir}} {{ppd_dir}}/{{ppd}}

clean:
    rm -rf build
