{ kubepkgs }:
kubepkgs.fetchCephDevel {
  pname = "ceph-19-devel";
  series = "squid";
  el = "9";
  lock = ./ceph-19-devel.json;

  meta.description = "Ceph 19 (Squid) librados and libradosstriper development headers";
}
