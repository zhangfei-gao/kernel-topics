#!/bin/bash
set -e

BOOT=out/arch/arm64/boot
DTB=${BOOT}/dts/qcom/nord-rrd-gearvm.dtb
IMAGE=${BOOT}/Image

mkbootimg.py \
	--header_version 2 \
	--kernel "${IMAGE}" \
	--dtb "${DTB}" \
	--ramdisk initramfs.cpio.gz \
	--base 0x80000000 \
	--kernel_offset 0x8000 \
	--ramdisk_offset 0x4c00000 \
	--dtb_offset 0x1f00000 \
	--pagesize 4096 \
	--cmdline "console=ttyMSM0,115200n8 earlycon=qcom_geni,0x884000 keep_bootcon root=/dev/ram0 cpuidle.off=1 clk_ignore_unused ignore_loglevel loglevel=8 panic=0 systemd.service_watchdogs=0 module_blacklist=coresight modprobe.blacklist=coresight" \
	--output boot.img
