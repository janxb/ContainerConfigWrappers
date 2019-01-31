#!/bin/bash
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

nano $DIR/generate.sh
$DIR/generate.sh
