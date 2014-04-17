#!/bin/sh

# Defaults
VERBOSE=0
INPUT="-"
OUTPUT="-"
TITLE="Homework"
AUTHOR="Student name"
SUBSET=""
DATE="$(date +%D)"
CLIENT="psql"
DATABASE=""
MYSQL=0
PSQL=0

# Read arguments
OPTS=`getopt -o vi:o:u:t:a:s:mpD: -l verbose,input:,output:,title:,author:,subset:,mysql,psql,database: -- "$@"`
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
        --subset|-s) SUBSET="${2}"; shift 2;;
        --mysql|-m) MYSQL=1; PSQL=0; shift;;
        --psql|-p) PSQL=1; MYSQL=0; shift;;
        --database|-D) DATABASE="${2}"; shift 2;;
        --) shift; break;;
    esac
done

if [ ${PSQL} -eq 1 ]; then
    if [ ! -e "${HOME}/.pgpass" ]; then
        echo "${HOME}/.pgpass is missing! Without it, you would need to enter your password for each question." >&2
        echo "You really should create it with the following contents:" >&2
        echo "*:*:${USER}:your_postgres_password" >&2
        echo "And then change its permissions to appease postgres:" >&2
        echo "chmod 0600 ${HOME}/.pgpass" >&2
        exit 1
    fi
elif [ ${MYSQL} -eq 1 ]; then
    if [ ! -e "${HOME}/.my.cnf" ]; then
        echo "${HOME}/.my.cnf is missing! Without it, you would need to enter your password for each question." >&2
        echo "You really should create it with the following contents:" >&2
        echo "[client]" >&2
        echo "password=<your password>" >&2
        echo "And then change its permissions to appease mysql:" >&2
        echo "chmod 0600 ${HOME}/.my.cnf" >&2
        exit 1
    fi
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

echo "${TITLE}" | output
echo "${DATE}" | output
echo "${AUTHOR} ${USER}" | output
echo ""

NL="
";
sql=""
delimiter=';'
ignore_errors=0
IFS=''
while read line <&${INFD}; do
    if echo "${line}" | grep -q -e "^--IGNORE_ERRORS [01]"; then
        ignore_errors="$(echo "${line}" | sed -e 's/.*IGNORE_ERRORS \([01]\).*/\1/')"
        continue
    fi
    sql="${sql}${NL}${line}"
    if echo "${line}" | grep -q "DELIMITER"; then
        delimiter="$(echo "${line}" | sed -e"s/DELIMITER //")"
    elif echo "${line}" | grep -q "${delimiter}"; then
        echo "${sql}" | output
        if [ "${PSQL}" -eq 1 ]; then
            echo "${sql}" | psql -v ON_ERROR_STOP=${ignore_errors} 2>&1 || exit $?
        elif [ "${MYSQL}" -eq 1 ]; then
            echo "${sql}" | mysql -D "${DATABASE}" \
                --table \
                --init-command='set sql_mode="ANSI_QUOTES"' *>&${OUTFD} \
                || [ ${ignore_errors} -eq 1 ] || exit $?
        fi
        sql=""
    fi
done

