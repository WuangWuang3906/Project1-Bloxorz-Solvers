"""Run every level x every algorithm without the GUI and write a CSV for the report.

Run: python benchmark/run_benchmark.py --levels levels --out results/benchmark.csv

TODO(benchmark): for each levels/*.json and each name in ALGORITHMS, call
run_solver(); write level, group, algo, found, length, cost, expanded, time_ms,
peak_kb. Repeat time measurement 3-5 times and keep the median. Add a safety
cap (team decision) so one hard level cannot block the whole run.
"""
