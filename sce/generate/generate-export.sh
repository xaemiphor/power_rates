#!/bin/bash
IFS=$'\n'
RATES=(
	'NBT23'
	'NBT24'
	'NBT00'
)
SOURCE="${1}"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DATA_DIR=$(dirname "${SCRIPT_DIR}")
YEAR=$(date -u +%Y)
START_TIME=$(date -u -d"${YEAR}-01-01 00:00:00" +%s)
END_TIME=$(date -u -d"$(( ${YEAR} + 1 ))-01-01 00:00:00" +%s)

if [[ -z "${SOURCE}" || ! -e "${SOURCE}" ]]; then
	echo "ERROR: ${SOURCE} doesn't exist or was undefined"
	exit 1
fi

genExcelDate() {
	echo $(( (${1} / 86400) + 25569 ))
}
genExcelTime() {
	HOUR=$(echo $(( (${1} / 60 / 60) % 24 )))
	echo "scale=8;${HOUR} / 24" | bc | sed 's/\.0*$//;s/\.\([0-9]*[1-9]\)0*$/.\1/'
}

CURRENT_TIME=${START_TIME}
while [ ${CURRENT_TIME} -lt ${END_TIME} ]; do
	NOW=$(date -u -d@${CURRENT_TIME} +'%Y-%m-%dT%H:00:00Z')
	YEAR=$(date -u -d@${CURRENT_TIME} +%Y)
	MONTH=$(date -u -d@${CURRENT_TIME} +%m)
	DAY=$(date -u -d@${CURRENT_TIME} +%d)
	HOUR=$(date -u -d@${CURRENT_TIME} +%H)

	EXCEL_DATE=$(genExcelDate ${CURRENT_TIME})
	EXCEL_TIME=$(genExcelTime ${CURRENT_TIME})
	if [[ ${EXCEL_TIME} != "0" ]]; then
		EXCEL_TIME="0${EXCEL_TIME}"
	fi
	for RATE in ${RATES[@]}; do
		if [[ ! -e "${DATA_DIR}/${RATE}.export/${YEAR}/${MONTH}/${DAY}/${HOUR}" || $(cat "${DATA_DIR}/${RATE}.export/${YEAR}/${MONTH}/${DAY}/${HOUR}") == "error" || $(cat "${DATA_DIR}/${RATE}.export/${YEAR}/${MONTH}/${DAY}/${HOUR}") =~ ^0[0-9]\. ]]; then
			VALUES=( $(awk -F ',' -v kind=${RATE} -v edate=${EXCEL_DATE} -v etime=${EXCEL_TIME} '$0~kind && $0~edate && $0~etime{print $10}' "${SOURCE}") )
			PRICE=0
			for val in ${VALUES[@]}; do
				PRICE=$(echo "${PRICE} + ${val}" | bc | sed 's/\.0*$//;s/\.\([0-9]*[1-9]\)0*$/.\1/')
			done
			if [[ ${PRICE:0:1} == "." ]]; then
				PRICE="0${PRICE}"
			fi
			if [[ ${#VALUES[@]} -eq 0 ]]; then
				PRICE="error"
			fi

			echo "${CURRENT_TIME} | ${NOW} | ${EXCEL_DATE} ${EXCEL_TIME} | ${PRICE}"
			if [[ ! -d "${DATA_DIR}/${RATE}.export/${YEAR}/${MONTH}/${DAY}" ]]; then
				mkdir -p "${DATA_DIR}/${RATE}.export/${YEAR}/${MONTH}/${DAY}"
			fi
			echo "${PRICE}" > "${DATA_DIR}/${RATE}.export/${YEAR}/${MONTH}/${DAY}/${HOUR}"

		fi
	done
	CURRENT_TIME=$(date -d@$(( ${CURRENT_TIME} + (60*60) )) +%s)
done
