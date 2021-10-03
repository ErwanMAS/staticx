#!/bin/bash
set -e

echo -e "\n\nEnsure StaticX detects unsupported libraries using RUNPATH"

cd "$(dirname "${BASH_SOURCE[0]}")"

app="dist.runpath/bin/app"
outfile="dist.runpath/app.staticx"

# Build the application
# Force use of RUNPATH, not RPATH
# https://stackoverflow.com/a/52020177/119527
scons --quiet name=runpath LINKFLAGS='-Wl,--enable-new-dtags'

# Ensure this test uses DT_RUNPATH and not DT_RPATH
if (readelf -d $app | grep -q '(RPATH)'); then
    echo "TEST ERROR: app uses DT_RPATH instead of DT_RUNPATH"
    exit 66
fi
if ! (readelf -d $app | grep -q '(RUNPATH)'); then
    echo "TEST ERROR: app is missing DT_RUNPATH"
    exit 66
fi

# Run the application normally
echo -e "\nApp run normally:"
$app

# Make a staticx executable from it
# This is an expected failure!
echo -e "\nMaking staticx executable (\$STATICX_FLAGS=$STATICX_FLAGS) [EXPECTED FAILURE]:"
if (staticx $STATICX_FLAGS $app $outfile) ; then
    echo "FAIL: Staticx permitted a problematic library using RUNPATH"
    exit 66
fi
echo "Success"
