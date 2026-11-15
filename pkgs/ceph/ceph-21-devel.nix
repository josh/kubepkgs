{ kubepkgs }:
kubepkgs.fetchCephDevel {
  pname = "ceph-21-devel";
  series = "umbrella";
  el = "10";
  lock = ./ceph-21-devel.json;

  meta.description = "Ceph 21 (Umbrella) librados and libradosstriper development headers";
}
