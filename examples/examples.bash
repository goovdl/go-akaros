#!/usr/bin/env bash
# Copyright 2013 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Trap and exit script if ^C sent
trap "exit 1" INT TERM

BINDIR="bin"

# Print the usage information for this script
usage()
{
cat << EOF
This script will build and install a list of go programs into
\$ROSROOT/kern/kfs/bin. The go files passed to this script must all be self
contained, in that the entire program is contained in a single file.
usage: $0 options
OPTIONS:
   -h      This is the default option
           Show this message
   -a      Build and install all *.go files in the current directory
   -b      Build and install the list of *.go files that follow this option.
           If you have more than one go file, wrap the list in double quotes
           (e.g. $0 -b "file1.go file2.go file3.go").
   -t      Build and install all tests from \$GOROOT/src/pkg
   -c      Clean (i.e. remove all non *.go files and known scripts)
   -v      Verbose mode
EOF
}

# Source a local.bash file in case the user wants to put his environment
# variable setup in there
if [ -f ../src/local.bash ]; then
    source ../src/local.bash
fi

# Get the options from the command line
GOPROGS=""
TEST=""
CLEAN=""
VERBOSE=""
while getopts “hab:tcv” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         a)
             GOPROGS=`ls *.go`
             ;;
         b)
             GOPROGS="$OPTARG"
             ;;
         c)
             CLEAN=1
             ;;
         t)
             TEST=1
             ;;
         v)
             VERBOSE=1
             ;;
     esac
done

# If we didn't pass any go files to build, then print our usage message and
# exit the script
if [[ "$GOPROGS" = "" ]] &&
   [[ "$TEST" != "1" ]]    &&
   [[ "$CLEAN" != "1" ]]
then
  usage
  exit 1
fi

# If cleaning, cleanup then exit
if [[ "$CLEAN" = "1" ]]; then
  rm -rf ${BINDIR}
  exit 1
fi

# A run helper to echo our command before executing it
# Build the run helper differently depending on whether verbose was passed in
if [[ "$VERBOSE" = "1" ]]; then
  run_helper() { echo "$@"; "$@"; }
else
  run_helper() { "$@"; }
fi

# Loop over all the arguments and assume they are standalone go files we want
# to build and install into akaros
if [[ "$GOPROGS" != "" ]]; then
  mkdir -p ${BINDIR}
  for i in ${GOPROGS}; do
    run_helper go-${GOOS}-${GOARCH} build $i
    i=${i##*/}
    i=${i%.go}
    run_helper cp $i ${ROSROOT}/kern/kfs/bin/
    mv $i ${BINDIR}
  done
fi

# Build and install all of the tests
if [[ "$TEST" != "" ]]; then
  cd ../src
  TESTS=$(find pkg -name "*_test.go" \
         | sed 's#\(.*\)/.*#\1#' \
         | sed 's/^pkg\///' \
         | grep -v 'runtime/race' \
         | sort -u)
  cd - > /dev/null
  
  mkdir -p ${BINDIR}
  for t in ${TESTS}; do
    run_helper go-${GOOS}-${GOARCH} test $t
    t="${t##*/}.test"
    run_helper cp $t ${ROSROOT}/kern/kfs/bin/
    mv $t ${BINDIR}
  done
fi
