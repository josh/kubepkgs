{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lord-alfred-ipranges";
  version = "0-unstable-2026-09-20";

  src = fetchFromGitHub {
    owner = "lord-alfred";
    repo = "ipranges";
    rev = "b7ccac2d117031a47822ad182abf7a1c32330764";
    hash = "sha256-vMb6VmirseWTSYoGt3VoH/lQnoG8ZZZaATtuOof5a68=";
  };

  installPhase = ''
    runHook preInstall

    find . -mindepth 2 -maxdepth 2 -name 'ipv[46]*.txt' -exec install -D --mode=0644 {} $out/{} \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  passthru.tests = {
    cidrs =
      runCommand "test-lord-alfred-ipranges-cidrs"
        {
          __structuredAttrs = true;
        }
        ''
          for f in all/ipv4.txt all/ipv6.txt amazon/ipv4.txt github/ipv4.txt; do
            [ -s "${finalAttrs.finalPackage}/$f" ]
          done
          if grep --recursive --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$' ${finalAttrs.finalPackage}; then
            exit 1
          fi
          touch $out
        '';
  };

  meta = {
    description = "IP ranges for Google, Bing, Amazon, Microsoft, GitHub, and other providers";
    homepage = "https://github.com/lord-alfred/ipranges";
    license = lib.licenses.cc0;
    platforms = lib.platforms.all;
  };
})
