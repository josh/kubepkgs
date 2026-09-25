{
  runCommand,
  pname,
  file,
  generated,
}:
runCommand "test-${pname}-crds" { } ''
  if ! diff -u ${file} ${generated}; then
    echo "committed CRD module for ${pname} is stale; run: nix run .#update-crd-modules -- --write" >&2
    exit 1
  fi
  touch $out
''
