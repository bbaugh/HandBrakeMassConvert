#!/bin/sh
# Set default for arguments
indir=""
intype="avi"
outdir=""
outtype="m4v"
preset="High"
handbrakecli=`which HandBrakeCLI `
dold=0
# show program usage
function show_usage()
{
  echo
  echo ${shname}" Usage:"
  echo "  Processes a plan file and makes PBS submission scripts."
  echo "${shname} -[iINDIR|i INDIR] -[tINTYPE|t INTYPE]"
  echo "          -[oOUTDIR|o OUTDIR] -[TOUTTYPE|T OUTTYPE]"
  echo "          -[pPRESET|p PRESET] "
  echo "          -D -H"
  echo " At least one argument required. Used -R for defaults."
  echo " INDIR - Directory in which all files of type INTYPE will be converted."
  echo "         DEFAULT: ${indir}"
  echo " INTYPE - Type of files which will be converted in INDIR."
  echo "         DEFAULT: ${intype}"
  echo " OUTDIR - Directory where converted files will be placed."
  echo "          INDIR will be replaced with OUTDIR in saved file."
  echo "          If OUTDIR is unset then output will be in same dir as input."
  echo "          DEFAULT: ${outdir}"
  echo " OUTTYPE -  Filename suffix which will be output."
  echo "         DEFAULT: ${outtype}"
  echo " PRESET - Handbrake preset to use."
  echo "         DEFAULT: ${preset}"
  echo " D - Flag to delete old file"
  echo " H - Flag to display help"
  exit
}

# Parse arguments
while getopts ":i:t:p:T:o:DH" opt; do
  case $opt in
    i)
      indir=$OPTARG
      ;;
    t)
      intype=$OPTARG
      ;;
    o)
      outdir=$OPTARG
      ;;
    T)
      outtype=$OPTARG
      ;;
    p)
      preset=$OPTARG
      ;;
    D)
      dold=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      show_usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      show_usage
      ;;
  esac
done

if [ "${indir}" == "" ]; then
  echo "INDIR required!"
  show_usage
fi

if [ ! -r "${indir}" ]; then
  echo "Cannot read ${indir}"
  show_usage
fi

if [ ! -w "${indir}" ]; then
  echo "Cannot write to ${indir}"
  show_usage
fi

if [ "${outdir}" != "" ]; then
  if [ ! -x "${outdir}" ]; then
    mkdir -p "${outdir}" || { echo "Failed to create OUTDIR!"; show_usage;}
  fi
  if [ ! -w "${outdir}" ]; then
    echo "Cannot write to ${outdir}"
    show_usage
  fi
fi

if [ "${handbrakecli}" == "" ]; then
  echo "HandBrakeCLI not found in PATH!"
  show_usage
fi

if [ ! -x "${handbrakecli}" ]; then
  echo "Cannot execute ${handbrakecli}"
  show_usage
fi

presets=( `${handbrakecli} -z | grep "+" | sed -e 's/^[^+]*+\s*\([^:]*\):.*/"\1"/g' -e 's/^\s*//' `)

good=0
for p in ${presets[*]}; do
  if [ "${p}" == "${preset}" ]; then
    good=1
    break
  fi
done

if [ ${good} -ne 1 ]; then
  echo "Preset (${preset}) not supported by ${handbrakecli}!"
  show_usage
fi

files=( `find ${indir} -type f -name "*.${intype}" `)
if [ ${#files[*]} -le 0 ]; then
  echo "No files to process"
  exit
fi

for f in ${files[*]}; do
  outf=${f%.$intype}.$outtype
  if [ "${outdir}" != "" ]; then
    outf=${outf/${indir}/${outdir}}
  fi
  if [ -e "${outf}" ]; then
    continue
  fi
  echo "Processing $f"
  ${handbrakecli} -i "${f}" -o "${outf}" --preset="${preset}" && [[ ${dold} -eq 1 ]] && rm -f ${f};
done
