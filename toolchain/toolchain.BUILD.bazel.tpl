"""%generated_header%
"""

load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load("@%workspace_name%//:config.bzl", "cc_toolchain_config")

toolchain(
    name = "toolchain",
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:%target_arch%",
    ],
    toolchain = ":cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain(
    name = "cc_toolchain",
    all_files = ":all_files",
    ar_files = ":ar_files",
    as_files = ":as_files",
    compiler_files = ":compiler_files",
    dwp_files = ":dwp_files",
    linker_files = ":linker_files",
    objcopy_files = ":objcopy_files",
    strip_files = ":strip_files",
    supports_param_files = 0,
    toolchain_config = ":cc_toolchain_config",
    toolchain_identifier = "gcc-toolchain",
)

cc_toolchain_config(
    name = "cc_toolchain_config",
)

filegroup(
    name = "all_files",
    srcs = [
        ":ar_files",
        ":as_files",
        ":compiler_files",
        ":dwp_files",
        ":linker_files",
        ":objcopy_files",
        ":strip_files",
    ],
)

# GCC

filegroup(
    name = "compiler_files",
    srcs = [
        ":gcc",
        ":include",
    ],
)

filegroup(
    name = "linker_files",
    srcs = [
        ":gcc",
        ":lib",
        ":linker_files_binutils",
    ],
)

filegroup(
    name = "include",
    srcs = glob([
        "include/**",
        "%target_arch%-buildroot-linux-gnu/include/**",
    ]),
)

filegroup(
    name = "lib",
    srcs = glob([
        "lib/**",
        "lib64/**",
        "%target_arch%-buildroot-linux-gnu/lib/**",
        "%target_arch%-buildroot-linux-gnu/lib64/**",
    ]),
)

filegroup(
    name = "gcc",
    srcs = [
        ":gpp",
        "bin/%target_arch%-linux-cpp",
        "bin/%target_arch%-linux-gcc",
    ],
)

filegroup(
    name = "gpp",
    srcs = ["bin/%target_arch%-linux-g++"],
)

# Binutils

filegroup(
    name = "ar_files",
    srcs = [":ar"],
)

filegroup(
    name = "as_files",
    srcs = [":as"],
)

filegroup(
    name = "dwp_files",
    srcs = [],
)

filegroup(
    name = "linker_files_binutils",
    srcs = [
        ":ar",
        ":ld",
    ],
)

filegroup(
    name = "objcopy_files",
    srcs = [":objcopy"],
)

filegroup(
    name = "strip_files",
    srcs = [":strip"],
)

filegroup(
    name = "ld",
    srcs = [
        "bin/%target_arch%-linux-ld",
        "bin/%target_arch%-linux-ld.bfd",
    ],
)

filegroup(
    name = "ar",
    srcs = ["bin/%target_arch%-linux-ar"],
)

filegroup(
    name = "as",
    srcs = ["bin/%target_arch%-linux-as"],
)

filegroup(
    name = "nm",
    srcs = ["bin/%target_arch%-linux-nm"],
)

filegroup(
    name = "objcopy",
    srcs = ["bin/%target_arch%-linux-objcopy"],
)

filegroup(
    name = "objdump",
    srcs = ["bin/%target_arch%-linux-objdump"],
)

filegroup(
    name = "ranlib",
    srcs = ["bin/%target_arch%-linux-ranlib"],
)

filegroup(
    name = "readelf",
    srcs = ["bin/%target_arch%-linux-readelf"],
)

filegroup(
    name = "strip",
    srcs = ["bin/%target_arch%-linux-strip"],
)
