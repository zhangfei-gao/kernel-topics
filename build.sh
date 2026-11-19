#!/bin/bash
set -e
OUT=out
BOARD=rrd
RUN_DT_CHECK=0
JOBS=192

for arg in "$@"; do
	case "${arg}" in
	0|rrd)
		BOARD=rrd
		;;
	1|ride|ride-sx)
		BOARD=ride
		;;
	dtb)
		RUN_DT_CHECK=1
		;;
	-j*)
		JOBS="${arg#-j}"
		;;
	*)
		echo "Usage: $0 [rrd|ride] [dtb] [-jN]" >&2
		exit 2
		;;
	esac
done

case "${JOBS}" in
	''|*[!0-9]*)
		echo "Invalid job count: -j${JOBS}" >&2
		exit 2
		;;
esac

make O=${OUT} defconfig
if [ "${RUN_DT_CHECK}" -eq 1 ]; then
	DT_DOC_CHECKER=$(command -v dt-doc-validate || true)
	if [ -z "${DT_DOC_CHECKER}" ]; then
		echo "dt-doc-validate not found in PATH" >&2
		exit 1
	fi

	DT_PYTHON=$(sed -n '1s/^#!//p' "${DT_DOC_CHECKER}")
	if [ ! -x "${DT_PYTHON}" ] || \
	   ! "${DT_PYTHON}" -c 'import ruamel.yaml' >/dev/null 2>&1; then
		echo "Unable to find the Python environment used by dtschema" >&2
		exit 1
	fi

	rm -f "${OUT}"/arch/arm64/boot/dts/qcom/*.dtb

	make O=${OUT} -j${JOBS} \
		PYTHON3="${DT_PYTHON}" \
		dt_binding_check

	make O=${OUT} -j${JOBS} \
		PYTHON3="${DT_PYTHON}" CHECK_DTBS=1 \
		qcom/nord-rrd.dtb qcom/nord-ride-embedded.dtb \
		qcom/nord-rrd-gearvm.dtb
	exit 0
fi
make O=${OUT} -j${JOBS} Image.gz dtbs modules

[ -d ${OUT}/mymodules ] && rm -rf ${OUT}/mymodules
make O=${OUT} INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=mymodules/usr -j${JOBS} modules_install

# Optional files for the initramfs.  Put files under ramfs-extra/ using
# their target paths, for example ramfs-extra/usr/bin/nord.sh.
if [ -d ramfs-extra ]; then
	cp -a ramfs-extra/. ${OUT}/mymodules/
fi

KERNEL_VERSION=$(make O=${OUT} -s kernelrelease)
rm ${OUT}/mymodules/usr/lib/modules/${KERNEL_VERSION}/build
cd ${OUT}/mymodules && find . -print0 | cpio --null -o -H newc > ../../mymodules.cpio && cd ../../

cat initramfs-tiny-image-qcom-armv8a.cpio mymodules.cpio > initramfs.cpio

[ -f initramfs.cpio.gz ] && rm initramfs.cpio.gz
gzip initramfs.cpio
