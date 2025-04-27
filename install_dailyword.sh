#!/bin/bash
######################################################################
# Name:         install_dailyword.sh
#
# Description:  This script automates the process of downloading and
#               installing a package from a GitHub release.
#
# Details:
#   - It constructs the download URL based on the repository name,
#     package name, and version.
#   - Uses curl to download the .deb package.
#   - Installs the package using dpkg, and if there are dependency issues,
#     attempts to correct them using apt-get.
#   - Cleans up by removing the downloaded package file.
#
# Requirements:
#   - curl, dpkg, and apt-get must be available on the system.
#   - The script must be run with sufficient privileges to install packages.
#
# Usage:
#   Run this script to automatically download and install the specified
#   package from its GitHub release URL.
#
# Author:       github.com/brooks-code
# Date:         2025-04-15
######################################################################

set -e

REPO="brooks-code/fuzzy-carnival"
PACKAGE="dailyword.deb"
VERSION="v1.0.1"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${PACKAGE}"

echo "Downloading ${PACKAGE} from ${DOWNLOAD_URL}..."
curl -L -o "${PACKAGE}" "${DOWNLOAD_URL}"

echo "Installing ${PACKAGE}..."
sudo dpkg -i "${PACKAGE}" || sudo apt-get install -f -y

echo "Cleaning up the package..."
rm -f "${PACKAGE}"

echo "Installation successful!"
