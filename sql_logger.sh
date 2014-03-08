#!/bin/sh

# Defaults
VERBOSE=0
INPUT="-"
OUTPUT="-"
TITLE="Homework"
AUTHOR=""
USER="${USER}"
#SUBSET=""
DATE="$(date +%D)"

if [ "${#}" -lt 1 ]; then
    echo "Usage: ${0} <options>" >&2
    echo "  --verbose|-v    Print output to screen and to output file" >&2
    echo "  --input|-i      File to read from, or \"-\" for stdin (default: \"${INPUT}\")" >&2
    echo "  --output|-o     File to write to, or \"-\" for stdout (default: \"${OUTPUT}\")" >&2
    echo "  --title|-t      Title to be output (default: \"${TITLE}\")" >&2
    echo "  --author|-a     Author to be output (default: \"${AUTHOR}\")" >&2
    echo "  --user|-u       User to be output and used with psql (default: \"${USER}\")" >&2
    #echo "  --subset|-s     Subset of SQL commands to execute, separated by commas, or leave empty to execute all: E.G. 1,2,5 (default: \"${SUBSET}\")" >&2
    echo ""
    echo "  Example: ./sql_logger -i homework3.sql -o homework3_output.txt -a \"Joe Student\" -t \"Homework #3\"" >&2
    exit 1
fi

# Read arguments
OPTS=`getopt -o vi:o:t:a:u:s: -l verbose,input:,output:,title:,author:,user:,subset: -- "$@"`
if [ $? != 0 ]
then
    exit 1
fi
eval set -- "$OPTS"
while true ; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift;;
        --input|-i) INPUT="${2}"; shift 2;;
        --output|-o) OUTPUT="${2}"; shift 2;;
        --title|-t) TITLE="${2}"; shift 2;;
        --author|-a) AUTHOR="${2}"; shift 2;;
        --user|-u) USER="${2}"; shift 2;;
        #--subset|-s) SUBSET="${2}"; shift 2;;
        --) shift; break;;
    esac
done

if [ ! -e "${HOME}/.pgpass" ]; then
    echo "${HOME}/.pgpass is missing! Without it, you would need to enter your password for each question." >&2
    echo "You really should create it with the following contents:" >&2
    echo "*:*:${USER}:your_postgres_password" >&2
    echo "And then change its permissions to appease postgres:" >&2
    echo "chmod 0600 ${HOME}/.pgpass" >&2
    exit 1
fi

OUTFD=1
if [ "${OUTPUT}" != "-" ]; then
    OUTFD=5
    exec 5>${OUTPUT}
else
    VERBOSE=0 # Ignore verbose, we're arleady printing to stdout
fi

INFD=1
if [ "${INPUT}" != "-" ]; then
    INFD=6
    exec 6<${INPUT}
fi

output() {
    if [ ${VERBOSE} -ne 0 ]; then
        cat
    fi
    cat >&${OUTFD}
}

export PGUSER="${USER}"

echo "${TITLE}" | output
echo "${DATE}" | output
echo "${AUTHOR} ${USER}" | output
echo ""

sql=""
while read line <&${INFD}; do
    echo "${line}" | output
    if echo "${line}" | grep -v -q -e "^--"; then
        sql="${sql}${line}"
        if echo "${line}" | grep -q ";"; then
            echo "${sql}" | psql -v ON_ERROR_STOP=1 || exit $?
            sql=""
        fi
    fi
done

