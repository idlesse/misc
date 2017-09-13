#!/usr/bin/env sh
set -e

SD_CARD="$1"
if [ "x$SD_CARD" == "x" ]; then
	echo "error: please specify the sd card path"
	exit 1
fi

SD_INFO="`fdisk -l ${SD_CARD}`"

TOTAL_SIZE="`echo "${SD_INFO}" | grep "${SD_CARD}:" | sed 's/.* \([0-9]*\) bytes, \([0-9]*\) sectors/\1/'`"
BLK_SIZE=512
BLK_NUM=$((${TOTAL_SIZE} / ${BLK_SIZE}))

#bl1 size is 8KB
BL1_SIZE=$((8 * 1024))
BL1_BLK_NUM=$((${BL1_SIZE} / ${BLK_SIZE}))

# bl2 size is 512KB
BL2_SIZE=$((512 * 1024))
BL2_BLK_NUM=$((${BL2_SIZE} / ${BLK_SIZE}))

SD_8K_START_BLK=$((${BLK_NUM} - 18))
# fix position for SDHC (IROM bug)
if [ ${TOTAL_SIZE} -gt 1990197248 ]; then
	SD_8K_START_BLK=$((${SD_8K_START_BLK} - 1024))
fi

SD_BL2_START_BLK=$((${SD_8K_START_BLK} - ${BL2_BLK_NUM}))

echo "SD_8K_START_BLK is ${SD_8K_START_BLK}"
echo "SD_BL2_START_BLK is ${SD_BL2_START_BLK}"

ORI_BIN="barebox.bin"
dd if=${ORI_BIN} of=${SD_CARD} obs=${BLK_SIZE} seek=${SD_BL2_START_BLK}
dd if=${ORI_BIN} of=${SD_CARD} obs=${BLK_SIZE} seek=${SD_8K_START_BLK} count=${BL1_BLK_NUM}
