# Packet Tracer Installer for CachyOS

This repository contains a script to automate the installation of Cisco Packet Tracer on Arch Linux and its derivatives (like CachyOS, Manjaro, EndeavourOS).

It handles the AUR package building process, fixes common issues with the latest version (like missing binaries or symlinks), and corrects permission errors that prevent the EULA from being accepted.

## Prerequisites

Due to Cisco's license agreement, you **must** download the installer manually.

1.  Go to the [Cisco Packet Tracer download page](https://www.netacad.com/resources/lab-downloads).
2.  Log in with your Networking Academy account.
3.  Download the **Packet Tracer 9.0.0 Ubuntu 64bit** (`.deb` file).

## Installation

1.  Clone this repository or download the script.
2.  Make the script executable:
    ```bash
    chmod +x install_packettracer.sh
    ```
3.  Run the script:
    ```bash
    ./install_packettracer.sh
    ```
4.  When prompted, drag and drop your downloaded `.deb` file into the terminal or paste the full path to it.

## What the script does

1.  **Checks Dependencies**: Installs `base-devel` and `git` if missing.
2.  **Clones AUR Package**: Fetches the latest `packettracer` package from the Arch User Repository.
3.  **Patches PKGBUILD**:
    - Dynamically finds the Packet Tracer binary (supports standard binaries and AppImages).
    - Creates the correct symlink at `/usr/bin/packettracer`.
    - Fixes `.desktop` file paths so the application appears in your menu.
4.  **Installs**: Builds and installs the package using `makepkg`.
5.  **Fixes Permissions**: Adjusts permissions on `~/.local/.packettracer` to ensure you can accept the EULA without "Permission denied" errors.

## Disclaimer

This script is not affiliated with Cisco Systems. Packet Tracer is a trademark of Cisco Systems, Inc.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.