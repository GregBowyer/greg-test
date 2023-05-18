{ pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  stdenv ? pkgs.llvmPackages_16.libcxxStdenv,
  llvmPkgs ? (pkgs.llvmPackages_16.override({
    stdenv = stdenv;
  }))
}:
let
  # This one is a little special, there is a nixos patch to enhance purity
  # but it has the side-effect of making sysroots not work.
  #
  # In the context of nixos this makes sense, but for our needs its problematic
  # As such we pull it out
  tm_clang =
    llvmPkgs.clang-unwrapped.overrideAttrs (new: old: {
      patches = builtins.filter
        (patch: baseNameOf patch != "add-nostdlibinc-flag.patch")
        old.patches;
      }
    );

  tm_compiler_rt =
    # Temp hack
    #
    # This isnt the _worst_ rebuild in the world
    # What we want to figure out is:
    # * How to get all the compiler-rt stuff from nixos
    # * How to avoid the rebuilds if possible
    # * How to get macos{aarch64,x86_64} and linux{aarch64,x86_64} in one install
    # * If we are bound to nixos or the sysroot glibc
    llvmPkgs.compiler-rt.overrideAttrs (new: old: {
    });
in
  pkgs.buildEnv {
    name = "llvm_buildenv";
    paths = [
        #llvmPkgs.compiler-rt
        llvmPkgs.libcxx
        llvmPkgs.libcxx.dev
        llvmPkgs.libcxxabi
        llvmPkgs.libcxxabi.dev
        llvmPkgs.libunwind
        llvmPkgs.libunwind.dev
        #llvmPkgs.libraries.compiler-rt-libc
        #llvmPkgs.libraries.compiler-rt-libc.dev
        #llvmPkgs.libraries.compiler-rt
        #llvmPkgs.libraries.compiler-rt.dev
        tm_compiler_rt
        tm_compiler_rt.dev
        llvmPkgs.lld
        llvmPkgs.llvm
        tm_clang
        tm_clang.lib

        # Temp hack:
        # How do we get nixos or clang to work out this is in a different place?
        (pkgs.runCommand "unfuckle" {} ''
          mkdir -p $out/lib/clang/16/lib
          ln -sv ${tm_compiler_rt}/lib/linux $out/lib/clang/16/lib/linux
        '')
    ];
   }
