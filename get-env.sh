#!/bin/bash

# Usage :
# bash get-env.sh [dev or nothing]

# Adds $dev to the scope
# Impacts oc-infos.xml and c14-infos.xml variables
if [ -z ${1+x} ]; then
    dev=""
elif [[ "$1" = "dev" ]]; then
    dev="dev"
else
    dev=""
fi

# Adds $env to the scope
# Impacts archive's names and descriptions
# Also determines the detection of the last archive or last bucket of the environment
if [[ $dev = "dev" ]]; then
    env="dev"
else
    env="prod"
fi

# Adds $progress to the scope
# Makes some commands more verbose in dev
# $progress applies to rsync, $v to MySQL and $s to curl
if [[ $dev = "dev" ]]; then
    progress="--progress"
    v="-v"
    s=""
else
    progress=""
    v=""
    s="-s"
fi
