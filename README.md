# Information
Automates libvirt cpu pinning + isolation.

NOTE: All cpu groups will be pinned excluding the last one since it's used for isolation.

# Usage
```
curl -O https://raw.githubusercontent.com/lexi-src/libvirt-CPU-pinner/master/pinner.sh
chmod +x pinner.sh
./pinner.sh
```
