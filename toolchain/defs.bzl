"""This module provides the definitions for registering a GCC toolchain for C and C++.
"""

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("//toolchain:unix_cc_configure.bzl", "get_cxx_include_directories", "get_no_canonical_prefixes_opt")

def _gcc_toolchain_impl(rctx):
    pwd = paths.dirname(str(rctx.path("WORKSPACE")))

    rctx.download_and_extract(
        sha256 = rctx.attr.sha256,
        stripPrefix = rctx.attr.strip_prefix,
        url = rctx.attr.url,
    )

    target_arch = rctx.attr.target_arch
    if rctx.attr.binary_prefix:
        binary_prefix = rctx.attr.binary_prefix
    else:
        binary_prefix = target_arch

    ar = str("bin/{}-linux-ar".format(binary_prefix))
    cpp = str("bin/{}-linux-cpp".format(binary_prefix))
    gcc = str("bin/{}-linux-gcc".format(binary_prefix))
    gcov = str("bin/{}-linux-gcov".format(binary_prefix))
    ld = str("bin/{}-linux-ld".format(binary_prefix))
    nm = str("bin/{}-linux-nm".format(binary_prefix))
    objcopy = str("bin/{}-linux-objcopy".format(binary_prefix))
    objdump = str("bin/{}-linux-objdump".format(binary_prefix))
    strip = str("bin/{}-linux-strip".format(binary_prefix))

    tool_paths = {
        "ar": ar,
        "cpp": cpp,
        "gcc": gcc,
        "gcov": gcov,
        "ld": ld,
        "nm": nm,
        "objcopy": objcopy,
        "objdump": objdump,
        "strip": strip,
    }

    generated_header = "GENERATED - This file was generated by the repository target @{}.".format(rctx.name)

    if rctx.attr.platform_directory:
        platform_directory = rctx.attr.platform_directory
    else:
        platform_directory = "{}-buildroot-linux-gnu".format(target_arch)

    if not rctx.path(platform_directory):
        fail("'platform_directory' does not exist")

    user_sysroot_path = ""
    builtin_sysroot = ""
    if rctx.attr.sysroot:
        sysroot_build_label = Label("@{workspace}//{package}:BUILD.bazel".format(
            workspace = rctx.attr.sysroot.workspace_name,
            package = rctx.attr.sysroot.package,
        ))
        user_sysroot_path = paths.dirname(str(rctx.path(sysroot_build_label)))
    else:
        if rctx.attr.use_builtin_sysroot:
            if rctx.attr.builtin_sysroot_path:
                builtin_sysroot = str(rctx.path(rctx.attr.builtin_sysroot_path))
            else:
                builtin_sysroot = str(rctx.path(paths.join(platform_directory, "sysroot")))
        builtin_sysroot = builtin_sysroot.rstrip("/")

    extra_cflags = [
        flag.format(
            sysroot = user_sysroot_path,
            toolchain_root = pwd,
        )
        for flag in rctx.attr.extra_cflags
    ]
    extra_cxxflags = [
        flag.format(
            sysroot = user_sysroot_path,
            toolchain_root = pwd,
        )
        for flag in rctx.attr.extra_cxxflags
    ]
    extra_ldflags = [
        flag.format(
            sysroot = user_sysroot_path,
            toolchain_root = pwd,
        )
        for flag in rctx.attr.extra_ldflags
    ]

    sysroot = user_sysroot_path or builtin_sysroot
    cxx_builtin_include_directories = collections.uniq(
        get_cxx_include_directories(
            rctx,
            gcc,
            "-xc",
            extra_cflags + (["--sysroot", sysroot] if sysroot else []),
        ) +
        get_cxx_include_directories(rctx, gcc, "-xc++") +
        get_cxx_include_directories(
            rctx,
            gcc,
            "-xc++",
            ["-stdlib=libc++"] + extra_cxxflags + (["--sysroot", sysroot] if sysroot else []),
        ) +
        get_cxx_include_directories(
            rctx,
            gcc,
            "-xc",
            get_no_canonical_prefixes_opt(rctx, gcc),
        ) +
        get_cxx_include_directories(
            rctx,
            gcc,
            "-xc++",
            get_no_canonical_prefixes_opt(rctx, gcc),
        ) +
        get_cxx_include_directories(
            rctx,
            gcc,
            "-xc++",
            get_no_canonical_prefixes_opt(rctx, gcc) + ["-stdlib=libc++"],
        ),
    )
    cxx_builtin_include_directories = [
        paths.join(pwd, include)
        for include in cxx_builtin_include_directories
    ]

    target_compatible_with = [
        str(Label(v.format(target_arch = target_arch)))
        for v in rctx.attr.target_compatible_with
    ]

    substitutions = {
        "__bazel_gcc_toolchain_workspace_name__": rctx.attr.bazel_gcc_toolchain_workspace_name,
        "__binary_prefix__": binary_prefix,
        "__generated_header__": generated_header,
        "__platform_directory__": platform_directory,
        "__target_arch__": target_arch,
        "__target_compatible_with__": str(target_compatible_with),

        # Sysroot
        "__user_sysroot_path__": user_sysroot_path,
        "__user_sysroot_label__": str(rctx.attr.sysroot) if rctx.attr.sysroot else "",
        "__builtin_sysroot__": builtin_sysroot,

        # Includes
        "__cxx_builtin_include_directories__": str(cxx_builtin_include_directories),

        # Flags
        "__extra_cflags__": str(extra_cflags),
        "__extra_cxxflags__": str(extra_cxxflags),
        "__extra_ldflags__": str(extra_ldflags),

        # Tool paths
        "__tool_paths__": str(tool_paths),
    }
    rctx.template("BUILD.bazel", rctx.attr._toolchain_build_template, substitutions = substitutions)

_DOWNLOAD_TOOLCHAIN_ATTRS = {
    "sha256": attr.string(
        doc = "The SHA256 integrity hash for the interpreter tarball.",
        mandatory = True,
    ),
    "strip_prefix": attr.string(
        doc = "The prefix to strip from the extracted tarball.",
        mandatory = True,
    ),
    "url": attr.string(
        doc = "The URL of the interpreter tarball.",
        mandatory = True,
    ),
}

_FEATURE_ATTRS = {
    "bazel_gcc_toolchain_workspace_name": attr.string(
        doc = "The name give to the repository when imported bazel_gcc_toolchain.",
        default = "bazel_gcc_toolchain",
    ),
    "binary_prefix": attr.string(
        doc = "An explicit prefix used by each binary in bin/. Defaults to `<target_arch>`.",
        mandatory = False,
    ),
    "builtin_sysroot_path": attr.string(
        doc = "An explicit sysroot path inside the tarball. Defaults to `<platform_directory>/sysroot`.",
        mandatory = False,
    ),
    "extra_cflags": attr.string_list(
        doc = "Extra flags for compiling C. {sysroot} is rendered to the sysroot path.",
        default = [],
    ),
    "extra_cxxflags": attr.string_list(
        doc = "Extra flags for compiling C++. {sysroot} is rendered to the sysroot path.",
        default = [],
    ),
    "extra_ldflags": attr.string_list(
        doc = "Extra flags for linking. {sysroot} is rendered to the sysroot path.",
        default = [],
    ),
    "platform_directory": attr.string(
        doc = "An explicit directory containing the target platform extra directories. Defaults to `<target_arch>-buildroot-linux-gnu`.",
        mandatory = False,
    ),
    "sysroot": attr.label(
        doc = "A sysroot to be used instead of the builtin sysroot. If this attribute is provided, it takes precedence over the use_builtin_sysroot attribute.",
        mandatory = False,
    ),
    "target_arch": attr.string(
        doc = "The target architecture this toolchain produces. E.g. x86_64.",
        mandatory = True,
    ),
    "target_compatible_with": attr.string_list(
        default = [
            "@platforms//os:linux",
            "@platforms//cpu:{target_arch}",
        ],
        doc = "contraint_values passed to target_compatible_with of the toolchain. {target_arch} is rendered to the target_arch attribute value.",
        mandatory = False,
    ),
    "use_builtin_sysroot": attr.bool(
        default = True,
        doc = "Whether the builtin sysroot is used or not.",
    ),
}

_PRIVATE_ATTRS = {
    "_build_bootlin_template": attr.label(
        default = Label("//toolchain:BUILD.bootlin.tpl"),
    ),
    "_toolchain_build_template": attr.label(
        default = Label("//toolchain:toolchain.BUILD.bazel.tpl"),
    ),
}

gcc_toolchain = repository_rule(
    _gcc_toolchain_impl,
    attrs = dicts.add(
        _DOWNLOAD_TOOLCHAIN_ATTRS,
        _FEATURE_ATTRS,
        _PRIVATE_ATTRS,
    ),
)

def gcc_register_toolchain(name, **kwargs):
    """Declares a `gcc_toolchain` and calls `register_toolchain` for it.

    Args:
        name: The name passed to `gcc_toolchain`.
        **kwargs: The extra arguments passed to `gcc_toolchain`. See `gcc_toolchain` for more info.
    """
    gcc_toolchain(
        name = name,
        **kwargs
    )

    native.register_toolchains("@{}//:toolchain".format(name))
