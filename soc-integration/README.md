# SoC Integration

This folder documents how the Multi-Mode MAC accelerator was integrated into a SweRV EH1 RISC-V system. The third-party SoC sources (the SweRV EH1 core, the AXI crossbar, the LiteDRAM controller, the boot ROM, and the rest of the reference platform) are **not** redistributed here. They belong to the upstream project and are used under their own licenses.

Upstream project: RVfpga / SweRV EH1, from the Chips Alliance and Western Digital ecosystem.

## What was added

The MAC accelerator (`axi/mac_axi4_top.v`) was attached to the system AXI4-Full interconnect as a new slave peripheral. From software it is a memory-mapped device; from hardware it is one more port on the crossbar.

## Address map

The MAC was given its own region in the AXI address space:

| Region | Address range |
|---|---|
| Peripheral window via AXI-to-Wishbone bridge (boot ROM, UART, GPIO, SPI, system controller) | `0x8000_0000` to `0x8000_3FFF` |
| Multi-Mode MAC accelerator (AXI4-Full slave) | `0x8000_4000` to `0x8000_4FFF` |
| DDR2 main memory (LiteDRAM) | `0x0000_0000` to `0x0800_0000` |

The high-throughput paths (core, DDR2, and the MAC) sit directly on the AXI4-Full interconnect. The slower peripherals sit on a Wishbone bus reached through the AXI-to-Wishbone bridge.

## Crossbar changes

The reference interconnect was a two-slave crossbar (memory and I/O). It was extended to three slaves to make room for the MAC:

- The slave count parameter was raised from 2 to 3.
- A new entry for the MAC region was added to the address-map constant.
- A new set of AXI slave ports for the MAC was declared, mirroring the existing memory and I/O port declarations.
- The slave request and response arrays were widened by one element, with the new element wired to the MAC port.

The master side (instruction fetch, load/store, and sideband) was left unchanged. The modifications were confined to a small, parameterised section of the interconnect rather than touching the crossbar internals or the MAC wrapper.

## Software access

A small C driver running on the SweRV core writes the operands and mode into the MAC registers over AXI, triggers the operation, and reads the product and accumulated result back. Status messages were printed over UART, and bring-up was observed on hardware using the JTAG debug bridge and the Vivado integrated logic analyser on the MAC region of the crossbar.

## Reproducing the integration

1. Clone the upstream RVfpga / SweRV reference platform.
2. Add `axi/mac_axi4_top.v` and the `rtl/` sources from this repository to the project.
3. Apply the crossbar changes described above (slave count, address map, port declarations, request and response arrays).
4. Build the bitstream in Vivado and program the Nexys A7-100T.
