#!/bin/sh
# Copyright (c) 2021, Jeffrey Bencteux
# All rights reserved.

# This source code is licensed under the GPLv3 license found in the
# LICENSE file in the root directory of this source tree.

set -eu

usage()
{
    echo "Usage: $0 [OPTIONS]..."
    echo "Check sysctl values against a reference file."
    echo
    echo "Arguments:"
    echo "  -b print only failed and not found entries"
    echo "     specify twice to only show failed entries"
    echo "  -f reference file, format is as the 'sysctl -a' output"
    echo "  -h display this help and exit"
    echo "  -l log file to output to"
    echo "  -v verbose mode"
    echo "  -y avoid usage of terminal escape sequences"
    exit 0
}

log()
{
    echo "$1"

    if [ "$logging" -eq 1 ]; then
	echo "$1" >> "$l"
    fi
}

v=0
b=0
color=1
logging=0
f="refs/all.conf"

while getopts "bf:hl:vy" o; do
    case "${o}" in
        b)
            b=$(( b + 1 ))
            ;;
        y)
            color=0
            ;;
        f)
            f=${OPTARG}
            ;;
        h)
            usage
            ;;
	l)
	    logging=1
	    l=${OPTARG}
	    ;;
	v)
	    v=1
	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

log "  .-')                  .-')              .-') _                       ('-. .-..-. .-')   "
log " ( OO ).               ( OO ).           (  OO) )                     ( OO )  /\  ( OO )  "
log "(_)---\_)  ,--.   ,--.(_)---\_)   .-----./     '._ ,--.       .-----. ,--. ,--.,--. ,--.  "
log "/    _ |    \  \`.'  / /    _ |   '  .--./|'--...__)|  |.-')  '  .--./ |  | |  ||  .'   /  "
log "\  :\` \`.  .-')     /  \  :\` \`.   |  |('-.'--.  .--'|  | OO ) |  |('-. |   .|  ||      /,  "
log " '..\`''.)(OO  \   /    '..\`''.) /_) |OO  )  |  |   |  |\`-' |/_) |OO  )|       ||     ' _) "
log ".-._)   \ |   /  /\_  .-._)   \ ||  |\`-'|   |  |  (|  '---.'||  |\`-'| |  .-.  ||  .   \   "
log "\       / \`-./  /.__) \       /(_'  '--'\   |  |   |      |(_'  '--'\ |  | |  ||  |\   \  "
log " \`-----'    \`--'       \`-----'    \`-----'   \`--'   \`------'   \`-----' \`--' \`--'\`--' '--'  "
log ""
log ""


if [ ! -e "$f" ]; then
    echo "Input file $f does not exists"
    usage
fi

if [ ! -f "$f" ]; then
    echo "Input $f is not a file"
    usage
fi

log "Loading reference file $f"

if [ $logging -eq 1 ]; then
    log "Logging into $l"
fi

log ""

good=0
bad=0
error=0
notfound=0

while read -r line; do
    # ignoring empty lines
    if [ "$line" = "" ]; then
	continue
    fi

    # ignoring comments
    if echo "$line" | grep -q '^#'; then
	continue
    fi

    refname=$(echo "$line" | cut -d' ' -f1)
    retcode=0
    cur=$(sysctl -e "$refname") || retcode=$?

    if [ "$retcode" -ne 0 ]; then
	error=$((error + 1))
	continue
    elif [ "$line" = "$cur" ]; then
	good=$((good + 1))
	if [ $b -ge 1 ]; then
	    continue
	fi

	if [ $color -eq 1 ]; then
	    log "\e[1;32m[+]\e[0m $refname"
	else
	    log "[+] $refname"
	fi
    elif [ -z "$cur" ]; then
	notfound=$((notfound + 1))
	if [ $b -ge 2 ]; then
	    continue
	fi

	if [ $color -eq 1 ]; then
	    log "\e[1;33m[.]\e[0m $refname"
	else
	    log "[.] $refname"
	fi
    else
	bad=$((bad + 1))
	if [ $color -eq 1 ]; then
	    log "\e[1;31m[-]\e[0m $refname"
	else
	    log "[-] $refname"
	fi
    fi

    if [ $v -eq 1 ]; then
	log "reference: $line"
	if [ -n "$cur" ]; then
	    log "current  : $cur"
	else
	    log "current  : <not found>"
	fi
    fi
done < "$f"

log  ""
log "Statistics:"
log "  $good passed"
log "  $bad failed"
log "  $notfound not found"
log "  $error errors"
log "  $((good + bad + notfound + error)) total"
