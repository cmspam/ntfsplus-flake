# ntfsplus-flake for NixOS

Experience the next generation of NTFS support on Linux. **ntfsplus** is a modern, high-performance rewrite of the NTFS kernel driver, designed to replace the unmaintained `ntfs3` and the slow, userspace `ntfs-3g`.

## Why ntfsplus?
While `ntfs3` (Paragon) was a step forward, it has faced significant maintenance challenges and stability issues. **ntfsplus** (developed by Namjae Jeon, author of the kernel's exFAT driver) takes a "do-over" approach—building on the clean, readable foundation of the classic kernel NTFS driver and modernizing it with today's best practices.

### Key Benefits
* **Massive Write Performance**: Benchmarks show **35% to 110% faster** multi-threaded write speeds compared to `ntfs3`.
* **Modern IO Path**: Uses `iomap` and `folios` (replacing the legacy `buffer_head` system) for more efficient memory management and higher throughput.
* **Superior Stability**: Passes significantly more `xfstests` (287 vs 218 for `ntfs3`) and handles complex workloads (like concurrent directory operations) that often crash other drivers.
* **Instant Mounting**: Mounts large partitions (4TB+) in **under a second**, whereas `ntfs3` can take 4+ seconds.
* **Integrated Tooling**: Includes `ntfsprogs-plus`, finally bringing a working `fsck.ntfs` to the Linux kernel ecosystem for volume repair.

## Features
- **Nix-Native Build**: Automatically builds against your specific kernel version during system evaluation.
- **Conflict Management**: Sets up proper aliases and modprobe configurations to ensure `ntfsplus` is prioritized over legacy drivers.
- **Udev Integration**: Automatically identifies NTFS partitions and applies the correct filesystem environment variables.

---

## Usage

### 1. Add to your Flake inputs
In your flake.nix, add this repository as an input:

```
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  ntfsplus.url = "github:cmspam/ntfsplus-flake";
};
```

### 2. Import the Module
Include the module in your nixosSystem configuration:

```
outputs = { self, nixpkgs, ntfsplus, ... }: {
  nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./configuration.nix
      ntfsplus.nixosModules.default
    ];
  };
};
```

### 3. Enable in configuration.nix
Once the module is imported, you can enable it:

```
{ config, pkgs, ... }:
{
  services.ntfsplus.enable = true;
}
```

---

## Verification

After running nixos-rebuild switch and rebooting, you can verify the driver is active:

### Check the Kernel Module
```
modprobe ntfs
lsmod | grep ntfs
```

*Note: The module identifies as ntfs to maintain compatibility with standard mount commands, but it uses the ntfsplus implementation.*

### Check Utilities
Verify the high-performance utilities are present:
```
which fsck.ntfs
```

## Technical Implementation
This flake pulls the latest linux-ntfs source and compiles it as an out-of-tree module. It:
1. Bridges the driver into the kernel's extra module path.
2. Provides the ntfsprogs-plus userspace utilities from nixpkgs.
3. Configures modprobe so that mount -t ntfs uses this high-performance implementation.

## License
GPLv2 (Inherited from the Linux Kernel).
