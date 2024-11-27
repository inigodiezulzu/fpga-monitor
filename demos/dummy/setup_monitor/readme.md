# Setup Monitor

Using the Monitor infrastructure in Linux requires to load (i) the Monitor Linux driver and (ii) the Monitor device tree overlay, after the application bitstream is configured. This folder includes all the files and scripts needed.

### Folder Structure

- `modules/`: Contains the compiled Monitor kernel module.
- `overlays/`: Contains Monitor device tree overlays for different target platforms.
- `monitor_init.sh`: Script to copy the kernel module and overlay to the appropriate directories in the OS filesystem. Run the script on the target.
- `setup_monitor.sh`: Script to load the device tree overlay and kernel module. Run the script on the target, after the bitstream has been configured.
- `remove_monitor.sh`: Script to unload the device tree overlay and monitor driver. Run the script on the target.

## Instructions

1. Copy this folder on the target platform.
2. Run on target the `monitor_init.sh`script. It will copy the kernel module and overlay to their appropriate location on OS filesystem.
3. After the application bitstream is loaded, run on target the `setup_monitor.sh`script to load the kernel module and overlay.
4. When finished working with the Monitor, run on target the `remove_monitor.sh`script to unload the kernel module and overlay.

