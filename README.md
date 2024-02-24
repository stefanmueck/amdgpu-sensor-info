# amd-gpu-sensor-info

This is a bash script I use to periodically query and display various status information from my AMD GPU within Conky.
The script retrieves this information from the `/sys/class/hwmon/` subfolders and does its best to find the appropriate hardware monitoring subfolder for the `amdgpu` module. Once found, this information is cached. 