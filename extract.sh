#!/usr/bin/env bash
set -e

if [[ ! $# -eq 1 ]];
then
	echo "Usage: $0 BIOS_UPDATE.ROM"
	exit 1
fi

EXTRACTED_DIR=$1_extracted

rm -r $EXTRACTED_DIR
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
	IFS=$'\n'
	ENTRIES=($(xtensa-objdump -D $ELF | grep "entry.*a1," | awk -F ':' '{gsub(" +",""); print $1;}'))

	# add symbol to elf for each function entry
	touch $FLAT_ENTRIES
	for entry in "${ENTRIES[@]}"
	do
		echo "0x${entry} FUNC_${entry}" >> $FLAT_ENTRIES
	done

	cp $ELF $ELF.bak
	./wsym/wsym.py -f $FLAT_ENTRIES $ELF.bak $ELF
	rm $ELF.bak

	echo $ELF
done
