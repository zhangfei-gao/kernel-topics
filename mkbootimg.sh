#!/bin/bash
set -e

BOOT=out/arch/arm64/boot
IMAGE=${BOOT}/Image

case "${1:-0}" in
0)
	DTB=${BOOT}/dts/qcom/nord-rrd-gearvm.dtb
	;;
1)
	DTB=${BOOT}/dts/qcom/nord-ride.dtb
	;;
*)
	echo "Usage: $0 [0|1]" >&2
	echo "  0: RRD GearVM (default)" >&2
	echo "  1: Ride GearVM" >&2
	exit 2
	;;
esac

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
	--cmdline "console=ttyMSM0,115200n8 earlycon=qcom_geni,0x884000 keep_bootcon root=/dev/ram0 cpuidle.off=1 clk_ignore_unused ignore_loglevel loglevel=8 systemd.service_watchdogs=0 wcn_fw_test=8 qcom_scm.download_mode=1" \
	--output boot.img
