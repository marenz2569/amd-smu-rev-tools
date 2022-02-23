with import <nixpkgs> {};
let
  xtensa = stdenv.mkDerivation rec {
    name = "ghidra-xtensa";

    src = pkgs.fetchFromGitHub {
      owner = "Ebiroll";
      repo = "ghidra-xtensa";
      rev = "c4c5fcebd5169c4dcbacb9d761a95994e2ec1cb3";
      sha256 = "0x3h22zz7fn4gx1j7lxrjghk87l3x4hw4bpkn2firl2c60wzgl76";
    };

    buildInputs = with pkgs; [ perl zip ];

    buildPhase = ''
      GHIDRA_DIR=${pkgs.ghidra-bin.out}/lib/ghidra make release.zip
    '';

    installPhase = ''
      mkdir $out
      cp -r release/* $out
    '';

  };

  pkg_path = "$out/lib/ghidra";

  overlay = self: super: {
    # https://stackoverflow.com/questions/68523367/in-nixpkgs-how-do-i-override-files-of-a-package-without-recompilation/68523368#68523368
    my-ghidra = super.ghidra-bin.overrideAttrs (old: {
      # Using `buildCommand` replaces the original packages build phases.
      buildCommand = ''
        set -euo pipefail

        ${
          super.lib.concatStringsSep "\n"
            (map
              (outputName:
                ''
                  echo "Copying output ${outputName}"
                  set -x
                  cp -r "${super.ghidra-bin.${outputName}}" "''$${outputName}"
                  set +x
                ''
              )
              (old.outputs or ["out"])
            )
        }

        chmod -R +w $out

        cp -r ${xtensa.out}/* $out/lib/ghidra/Ghidra/Processors/

        rm -r $out/bin
        mkdir -p "$out/bin"
        ln -s "${pkg_path}/ghidraRun" "$out/bin/ghidra"
        chmod +x ${pkg_path}/ghidraRun

        sed -i "s+${super.ghidra-bin}+$out+" ${pkg_path}/support/launch.sh
      '';
    });

    psptool = with pkgs.python3Packages; buildPythonPackage rec {
      name = "psptool";

      src = pkgs.fetchFromGitHub {
        owner = "PSPReverse";
        repo = "PSPTool";
        rev = "f8991ab4de00a9e54769f197ab18c72ac6004e22";
        sha256 = "0zwpd5f942pfavnlxawjgqn5r0g8dnis8is8zz23wn3j2ddkhanz";
      };

      propagatedBuildInputs = [ cryptography prettytable ];
    };
  };
in
{ pkgsOverlay ? import <nixpkgs> { overlays = [ overlay ]; } }:
pkgsOverlay.mkShell {
  buildInputs = with pkgsOverlay; [
    my-ghidra  
    (binutils-unwrapped.overrideAttrs(old: { configureFlags = old.configureFlags ++ [ "--target=xtensa-elf" "--program-prefix=xtensa-" ]; doInstallCheck = false; configurePlatforms = [ ]; }))
    psptool
    python3
  ];
}
