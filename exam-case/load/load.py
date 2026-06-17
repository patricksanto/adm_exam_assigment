import os
import json
import duckdb
import pandas as pd
from pathlib import Path

# --------------------------------------------------
# Resolve paths relative to THIS file (not cwd)
# --------------------------------------------------

LOAD_DIR  = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.abspath(os.path.join(LOAD_DIR, ".."))

RAW_DIR = os.path.join(PROJECT_DIR, "raw")
DB_PATH = os.path.join(PROJECT_DIR, "f1.duckdb")

# --------------------------------------------------
# Helper: extract race_date, circuit, season from filename
# e.g. "20230827_Dutch Grand Prix_Race_laps.csv"
# --------------------------------------------------

def parse_filename(name: str):
    parts = name.split("_")
    date_raw = parts[0]                          # "20230827"
    circuit  = parts[1]                          # "Dutch Grand Prix"
    race_date = f"{date_raw[:4]}-{date_raw[4:6]}-{date_raw[6:]}"
    season    = int(date_raw[:4])
    return race_date, circuit, season

# --------------------------------------------------
# Connect and (re)create database
# --------------------------------------------------

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

con = duckdb.connect(DB_PATH)
print(f"Loading into: {DB_PATH}")

# --------------------------------------------------
# raw_laps  (all *_laps.csv combined)
# --------------------------------------------------

frames = []
for f in sorted(Path(RAW_DIR).glob("*_laps.csv")):
    df = pd.read_csv(f)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"]    = race_date
    df["circuit"]      = circuit
    df["season"]       = season
    df["source_file"]  = f.name
    frames.append(df)

raw_laps = pd.concat(frames, ignore_index=True)
con.execute("CREATE TABLE raw_laps AS SELECT * FROM raw_laps")
print(f"  raw_laps:            {len(raw_laps):>6} rows")

# --------------------------------------------------
# raw_session_results  (all *_session_results.json combined)
# --------------------------------------------------

frames = []
for f in sorted(Path(RAW_DIR).glob("*_session_results.json")):
    with open(f, encoding="utf-8") as fh:
        data = json.load(fh)
    df = pd.json_normalize(data)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"]   = race_date
    df["circuit"]     = circuit
    df["season"]      = season
    df["source_file"] = f.name
    frames.append(df)

raw_session_results = pd.concat(frames, ignore_index=True)
con.execute("CREATE TABLE raw_session_results AS SELECT * FROM raw_session_results")
print(f"  raw_session_results: {len(raw_session_results):>6} rows")

# --------------------------------------------------
# raw_weather  (all *_weather.csv combined)
# --------------------------------------------------

frames = []
for f in sorted(Path(RAW_DIR).glob("*_weather.csv")):
    df = pd.read_csv(f)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"]   = race_date
    df["circuit"]     = circuit
    df["season"]      = season
    df["source_file"] = f.name
    frames.append(df)

raw_weather = pd.concat(frames, ignore_index=True)
con.execute("CREATE TABLE raw_weather AS SELECT * FROM raw_weather")
print(f"  raw_weather:         {len(raw_weather):>6} rows")

# --------------------------------------------------
# raw_race_control  (all *_race_control_messages.csv combined)
# --------------------------------------------------

frames = []
for f in sorted(Path(RAW_DIR).glob("*_race_control_messages.csv")):
    df = pd.read_csv(f)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"]   = race_date
    df["circuit"]     = circuit
    df["season"]      = season
    df["source_file"] = f.name
    frames.append(df)

raw_race_control = pd.concat(frames, ignore_index=True)
con.execute("CREATE TABLE raw_race_control AS SELECT * FROM raw_race_control")
print(f"  raw_race_control:    {len(raw_race_control):>6} rows")

# --------------------------------------------------
# raw_schedule  (single schedule.txt, space-separated)
# --------------------------------------------------

schedule_path = os.path.join(RAW_DIR, "schedule.txt")
raw_schedule = pd.read_csv(schedule_path, sep=" ", quotechar='"')
con.execute("CREATE TABLE raw_schedule AS SELECT * FROM raw_schedule")
print(f"  raw_schedule:        {len(raw_schedule):>6} rows")

# --------------------------------------------------
# Done
# --------------------------------------------------

con.close()
print("\nAll raw tables loaded successfully.")
