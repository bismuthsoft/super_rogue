{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux.buildPackages;
    love_js =
      pkgs.buildNpmPackage rec {
        pname = "love.js";
        version = "11.4.1w";

        src = pkgs.fetchFromGitHub {
          owner = "winny-";  # fork because broken package-lock.json
          repo = pname;
          # Upstream doesn't appear to tag their releases.  So just trust me
          # bro.
          rev = "e11199bde1810426f3544379057ff73f0c5e0c8a";
          hash = "sha256-uN1VyT8WHB7fCYfmS6PvL2QginzysYreI3JQxPLlNTg=";
        };

        dontNpmBuild = true;
        npmDepsHash = "sha256-w5EN3qacmiASddaCCr2tDeJaG70R//Vi9eOHh7BUBdk=";


        meta = with pkgs.lib; {
          description = "Basically trying to adapt love.js to the latest and greatest versions of LÖVE and Emscripten.";
          homepage = "https://github.com/Davidobot/love.js";
          license = licenses.mit;
          maintainers = with maintainers; [ winny ];
        };
      };
    dot_love = pkgs.stdenv.mkDerivation {
      pname = "super_rogue.love";
      version = "0.0.1";
      # Pull in the game src dir directly so valid builds don't invalidate on
      # github actions edits.
      src = ./src;
      buildInputs = [ pkgs.zip ];
      buildPhase = ''
        zip -r super_rogue.love .
      '';
      installPhase = ''
        mkdir -p $out/
        cp super_rogue.love $out/
      '';
    };
    web_src = pkgs.stdenv.mkDerivation {
      pname = "super_rogue (web)";
      version = "0.0.1";
      src = ./.;
      buildInputs = [ love_js ];
      buildPhase = ''
        echo Super Rogue | love.js -c ${dot_love}/super_rogue.love public
      '';
      installPhase = ''
        cp -r public/ $out/
      '';
    };
    love_src = pkgs.copyPathToStore ./src;
    desktop = pkgs.writeShellScriptBin "super_rogue" ''
      exec ${pkgs.love}/bin/love ${dot_love}/super_rogue.love
    '';
    # Probably better way to do this?
    test = pkgs.writeShellScriptBin "super_rogue-test" ''
      exec ${pkgs.love}/bin/love ${dot_love}/super_rogue.love --test --headless
    '';
  in {
    packages.x86_64-linux.love_js = love_js;
    ci.s5cmd = pkgs.s5cmd;

    super_rogue = {
      inherit dot_love;
      inherit desktop;
      inherit test;
      web.src = web_src;
      web.serve = pkgs.writeShellScriptBin "super_rogue" ''
        echo Visit https://localhost:8080/
        exec ${pkgs.busybox}/bin/busybox httpd -f -h ${web_src} -v -p 8080
      '';
    };

    packages.x86_64-linux.default = web_src;

  };
}
