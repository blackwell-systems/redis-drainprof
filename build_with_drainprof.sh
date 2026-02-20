#!/bin/bash
set -e

echo "=== Complete clean build of Redis with drainprof instrumentation ==="

# Complete clean
make distclean
rm -rf deps/jemalloc/lib deps/jemalloc/include/jemalloc/jemalloc.h src/.make-settings

# Build jemalloc first with ENABLE_DRAINPROF
cd deps
make jemalloc
cd ..

# Build other deps
cd deps
make hiredis lua hdr_histogram fpconv linenoise
cd ..

# Force jemalloc setting
echo "MALLOC=jemalloc" > src/.make-settings

# Build Redis
MALLOC=jemalloc CFLAGS="-DENABLE_DRAINPROF" make -j4

# Verify
if [ -f src/redis-server ]; then
    echo "✓✓✓ BUILD SUCCESSFUL ✓✓✓"
    ./src/redis-server --version
    echo ""
    echo "To test FLUSHALL instrumentation:"
    echo "1. ./src/redis-server redis.conf"
    echo "2. redis-cli -p 6380 INFO MEMORY | grep drainprof"
else
    echo "✗ Build failed"
    exit 1
fi
