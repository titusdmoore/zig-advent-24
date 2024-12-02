{
  description = "Setup to use zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { nixpkgs, flake-utils, zig, ... } @ inputs:
  flake-utils.lib.eachDefaultSystem(system:
    let
      overlays = [
	      (final: prev: {
	      	zigpkgs = zig.packages.${prev.system};
	      })
      ];
       pkgs = import nixpkgs {
      	inherit system overlays;
      };
    in
    {
	    devShells.default = pkgs.mkShell {
		    buildInputs = with pkgs; [
		    	openssl
			pkg-config
			eza
			fd
		    	zigpkgs.master
		    ];
	    };
    }
  );
}
