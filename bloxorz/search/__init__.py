"""Solver registry: name -> solver(level, start) -> SearchResult."""
from bloxorz.search.astar import astar
from bloxorz.search.bfs import bfs
from bloxorz.search.dfs import dfs
from bloxorz.search.ucs import ucs

ALGORITHMS = {
    "bfs": bfs,
    "dfs": dfs,      # đổi thành ids nếu nhóm dùng IDS (ghi rõ trong báo cáo)
    "ucs": ucs,
    "astar": astar,
}
