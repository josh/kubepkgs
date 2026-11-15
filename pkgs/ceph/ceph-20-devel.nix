{ kubepkgs }:
kubepkgs.fetchCephDevel {
  pname = "ceph-20-devel";
  series = "tentacle";
  el = "9";
  lock = ./ceph-20-devel.json;

  meta.description = "Ceph 20 (Tentacle) librados and libradosstriper development headers";
}
