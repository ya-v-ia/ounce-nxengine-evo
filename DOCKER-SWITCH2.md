# Building for Switch 2 (ounce-devkit) with Docker

This builds `NXEngine-Evo-2.6.5.nro` with the Switch 2 toolchain from
[ounce-devkit](https://github.com/ounce-devkit) (`libounce` + `OunceVK`),
without installing devkitPro on the host.

## Prerequisites

- Docker
- An `ounce-devkit` image (the devkit that provides `libounce`,
  `portlibs/switch2` and the Switch 1 portlibs such as SDL2)

## One-shot build

From this directory:

```sh
docker build -f Dockerfile.build -t nxengine-evo-switch2 .

docker run --rm -v "$PWD:/work" -w /work nxengine-evo-switch2:latest bash ./build-switch2.sh
```

The NRO is written to `release/NXEngine-Evo-2.6.5.nro`.

## What the build does

1. Builds the `extract` helper with the **host** compiler (`PLATFORM=pc`).
   `Dockerfile.build` installs `libsdl2-dev`, `libsdl2-image-dev`,
   `libsdl2-mixer-dev`, `libpng-dev` and `libjpeg-dev` for this.
2. Downloads the Cave Story data (`cavestoryen.zip`) and the NXEngine
   translations, then runs `extract` to produce `release/data`.
3. Cross-compiles with the Switch 2 toolchain:

   ```sh
   source "$DEVKITPRO/switch2vars.sh"
   cmake -DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/libounce/cmake/Switch2.cmake" \
         -DPLATFORM=switch2 -DCMAKE_BUILD_TYPE=Release
   ```

   `Switch2.cmake` points `NX_ROOT` at `libounce`, so `-lnx` links libounce,
   `EGL`/`GLESv2` resolve to OunceVK in `portlibs/switch2`, and the CPU flags
   are the Switch 2's (from `libounce/switch2_cpu.mk`).
4. Packs the game data into the NRO's romfs with `nx_create_nro()`.

## Notes

- Requires network access to `github.com` and `cavestory.org`.
- Built and verified only as far as toolchain/link/packing; it has **not**
  been run on Switch 2 hardware.
- The NRO header produced by this devkit's `elf2nro` puts the standard
  `NRO0` header at offset `0x10`, behind a 16-byte `HOMEBREW` marker, with
  the `ASET` asset section (icon, nacp, romfs) at the end.
