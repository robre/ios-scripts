#!/bin/bash
# by twitter.com/r0bre

#uncomment if needed:
#set -eou pipefail
#trap ctrl_c INT

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 &&pwd)"  # script directory


userclientfinder(){
    tr '\t' ' ' | plutil -convert json -o - - | jq '. as $data | [path(..| select(scalars and (tostring | test("'"$1"'", "ixn")))) ] | map({ (.[0]|tostring): ([.[0]] as $path | .=$data | getpath($path)) | [.. | .IORegistryEntryName? + "(" + .IOObjectClass? + ")"] })'
}

getalluserclients(){
    ioreg -a -f -r -t -c IOUserClient 
}

iphoneexec(){
    # make sure iphone is on localhost port 2222, (iproxy 2222 22), and ssh key is already set up
    # echo "running on iphone: $@"
    ssh root@localhost -p2222 "$@"
}

iphoneuserclientfinder(){
    iotemp=$(iphoneexec mktemp)
    iphoneexec ln -s $iotemp /dev/stdout
    iphoneexec ioreg -a -f -r -t -c IOUserClient
    scp -P2222 root@localhost:$iotemp $iotemp
    iphoneexec rm $iotemp
    iphoneexec rm /dev/stdout
    cat $iotemp | userclientfinder $1
    rm $iotemp
}

help(){
    echo "iouserclientfinder.sh -- Help"
    echo "will find all iokit userclients that an application is currently attatched to"
    echo "results will be listed as paths in the ioregistry IORegistryEntryName(IOObjectClass)"
    echo "Usage:"
    echo "    ./iouserclientfinder.sh [-h/-U] APPLICATION"
    echo "Options:"
    echo "    -h: show this help"
    echo "    -U: use iPhone (on ssh localhost:2222)"
    echo ""
    echo "for this tool to work, you need ssh, tr, plutil and jq installed"
    echo "for -U to work, your iPhone needs to be mapped to localhost:2222 (e.g. with iproxy 2222 22), and ssh keys need to be set up"

}

if [[ $# -lt 1 ]]; then 
    help
    exit
fi
if [ "$1" = "-U" ]; then
    if [[ $# -lt 2 ]]; then 
        help
        exit
    fi
    iphoneuserclientfinder $2
elif [ "$1" = "-h" ]; then
    help
    exit
else
    getalluserclients | userclientfinder $1
fi

