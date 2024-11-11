#!/bin/bash

# Monitor integration on ARTICo3
#
# Author      : Juan Encinas <juan.encinas@upm.es>
# Date        : September 2024
# Description : This script is used to integrate the monitor project with ARTICo3.
#
#               It clones the ARTICo3 repository, copies the demo applications,
#               templates, libraries, drivers and device-tree files

# Variables
ARTICO3_REPO_URL="https://github.com/des-cei/artico3"       # ARTICo3 repository URL
COMMIT_HASH=67c0606dc841229a00423a60cb9d9cafc0098d1d        # ARTICo3 daemon commit hash
ARTICO3_DIR="artico3"                                       # ARTICo3 directory
MONITOR_PROJECT_DIR=$(pwd)                                  # Monitor project directory
INTEGRATION_DIR="files_to_integrate"                        # Integration directory
PATCHES_DIR="patches"                                       # Patches directory


# Clone the ARTICo3 repository
echo "Cloning the ARTICo3 repository..."
git clone "$ARTICO3_REPO_URL" "$ARTICO3_DIR"

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone ARTICo3 repository."
    exit 1
fi

echo "Successfully cloned ARTICo3 repository."

# Checkout the specific commit
echo "Checking out commit $COMMIT_HASH..."
cd "$ARTICO3_DIR" && git checkout "$COMMIT_HASH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to checkout commit $COMMIT_HASH."
    exit 1
fi

echo "Checked out commit $COMMIT_HASH successfully."

# Go back to the monitor project directory
cd "$MONITOR_PROJECT_DIR"

# Integrate the monitor in ARTICo3
echo "Integrating the monitor in ARTICo3..."
cp -r -P "$MONITOR_PROJECT_DIR/$INTEGRATION_DIR/." "$ARTICO3_DIR/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to integrate the monitor."
    exit 1
fi

echo "Successfully integrated the monitor in ARTICo3."

# Apply patch to the tools directory
echo "Applying patch to the tools directory..."
patch -p1 -d "$ARTICO3_DIR/tools" < $PATCHES_DIR/tools.patch

if [ $? -ne 0 ]; then
    echo "Error: Failed to apply patch to the tools directory."
    exit 1
fi

echo "Successfully applied patch to the tools directory."

echo "Monitor integration completed successfully."
