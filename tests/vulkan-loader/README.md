# Vulkan Loader ID-filter allocation regression

Vulkan Loader 1.4.367 includes upstream checks for both parse-buffer and filter-
array allocation, error propagation from both enumeration APIs, and cleanup.
The earlier PLANK production patch is removed. Prepared production sources must
match the pinned upstream tree, except for omitted upstream test fixtures.

The retained test patch adds 24 cases: physical-device/device-group enumeration,
count-only/output-array calls, each device/vendor/driver filter, and failure of
either allocation. Every case checks cleanup and a successful retry. Tests use
upstream fake ICDs and require no GPU. The test patch stays separate from the
product dependency preparation, which excludes the upstream tests directory.

In the parent PLANK checkout, run `bash scripts/test/qualify-vulkan-loader.sh`
on a hosted Linux builder. It uses the pinned GoogleTest/Headers/Loader sources,
runs allocation/filter tests and then removes the array allocation check only
in its disposable worktree. That negative control must fail. The root
`dependency-qualification.yml` workflow runs this gate without signing or
internal-machine access.

These checks do not qualify real drivers, FFmpeg/Vulkan encoding, static linking
or installed Host sessions. Those remain separate acceptance gates.
