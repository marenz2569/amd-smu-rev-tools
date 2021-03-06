#!/usr/bin/env bash
set -e

if [[ ! $# -eq 1 ]];
then
	echo "Usage: $0 BIOS_UPDATE.ROM"
	exit 1
fi

EXTRACTED_DIR=$1_extracted

rm -r $EXTRACTED_DIR || true
psptool -X -u -d 0 $1

IFS=$'\n'
SMU_FIRMWARES=($(find $EXTRACTED_DIR -type f -name '*SMU*'))

for firmware in "${SMU_FIRMWARES[@]}"
do
	TRIMMED=${firmware}_trimmed
	ELF=${firmware}.elf
	FLAT_ENTRIES=${firmware}.flat

	# copy the firmware and create elf
	dd bs=256 skip=1 if=$firmware of=$TRIMMED
	xtensa-objcopy -I binary -O elf32-xtensa-le $TRIMMED $ELF
	xtensa-strip $ELF

	# find all function entries in the firmware
	./find_funcs.py $TRIMMED > $FLAT_ENTRIES

	# add symbol to elf for each function entry
	cp $ELF $ELF.bak
	./wsym/wsym.py -f $FLAT_ENTRIES $ELF.bak $ELF
	rm $ELF.bak

	echo $ELF
done
