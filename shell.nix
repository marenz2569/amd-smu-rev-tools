with import <nixpkgs> {};
let
  xtensa = stdenv.mkDerivation rec {
    name = "ghidra-xtensa";

    src = pkgs.fetchFromGitHub {
      owner = "yath";
      repo = "ghidra-xtensa";
      rev = "e307f72005ccf70ba814c2b3b64fec786fffff22";
      sha256 = "175ikzwaadlj6kwi9smarx0pafzv6xrswnkyd62nmxyg850sk4v6";
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
  };
in
{ pkgsOverlay ? import <nixpkgs> { overlays = [ overlay ]; } }:
pkgsOverlay.mkShell {
  buildInputs = with pkgsOverlay; [
		my-ghidra	
    (binutils-unwrapped.overrideAttrs(old: { configureFlags = old.configureFlags ++ [ "--target=xtensa-elf" "--program-prefix=xtensa-" ]; doInstallCheck = false; configurePlatforms = [ ]; }))
  ];
}
