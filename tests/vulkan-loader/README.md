# Vulkan Loader ID-filter allocation regression

The required loader patch fixes the unchecked filter allocation introduced by
upstream `07e50bb6cc89025c37586efd215e2b8280670978`. Both physical-device and
device-group enumeration return `VK_ERROR_OUT_OF_HOST_MEMORY` if any ID-filter
array cannot be allocated. Previously allocated filters are freed through the
existing cleanup path; configured filtering is not silently bypassed.

The separate test patch adds 12 cases to the upstream test framework: both
enumeration APIs, count-only and output-array calls, and failures in each of the
device/vendor/driver filters. Each case checks allocation cleanup and a successful
retry. Tests use the upstream fake ICD and require no GPU. The test patch is kept
separate because dependency preparation excludes the upstream tests directory.

## Run

Start in this repository with the two Vulkan submodules initialized. Set
`GOOGLETEST_SOURCE` to a GoogleTest source checkout (upstream recommends v1.14.0),
and `CC`/`CXX` to a supported C/C++17 compiler if needed. These commands create an
isolated loader worktree and do not modify the dependency gitlink checkout:

```bash
review_root=$(pwd)
test_root=$(mktemp -d)
loader_commit=$(git -C third-party/FFmpeg/Vulkan-Loader rev-parse HEAD)
git -C third-party/FFmpeg/Vulkan-Loader worktree add --detach "$test_root/loader" "$loader_commit"
git -C "$test_root/loader" apply "$review_root/patches/FFmpeg/Vulkan-Loader/01-handle-id-filter-allocation-failure.patch"
git -C "$test_root/loader" apply "$review_root/tests/vulkan-loader/id-filter-allocation-tests.patch"

cmake -S third-party/FFmpeg/Vulkan-Headers -B "$test_root/headers-build" \
    -DCMAKE_INSTALL_PREFIX="$test_root/stage"
cmake --install "$test_root/headers-build"
cmake -S "$test_root/loader" -B "$test_root/loader-build" \
    -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="$test_root/stage" \
    -DGOOGLETEST_INSTALL_DIR="${GOOGLETEST_SOURCE:?Set the GoogleTest source path}"
cmake --build "$test_root/loader-build" --parallel 4
ctest --test-dir "$test_root/loader-build" --output-on-failure --timeout 60 \
    -R 'IdFilterAllocationFailure|DeviceFiltering|Allocation\.'
cmake -P tests/apply-git-patch.cmake
```

For a negative control, use a second clean worktree at the same loader commit
and apply **only** the test patch. The new allocation-failure test crashes in the
unpatched loader; with both patches it returns the Vulkan error and passes.
Do not run the negative control inside an application or a production session.

These tests do not qualify real drivers, FFmpeg/Vulkan encoding, static linking,
or a production dependency upgrade. This preparation-repository PR does not
change the maintained PLANK Host dependency pin.

For the complete upstream suite, run CTest without `-R`. The explicit `lib`
install directory accommodates its package-discovery test, which searches
`lib/pkgconfig` rather than platform-specific paths such as `lib64/pkgconfig`.
