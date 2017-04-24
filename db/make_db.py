import sqlite3


dbfile = 'MWA-GRB.sqlite'

schema = """
PRAGMA foreign_keys=ON;

CREATE TABLE grb
(name TEXT PRIMARY KEY,
fermi_trigger_id INT,
swift_trigger_id INT,
best_ra FLOAT,
best_dec FLOAT,
pos_err FLOAT,
best_pos_ref TEXT);

CREATE TABLE observation
(
obs_id INT PRIMARY KEY,
project TEXT,
lst FLOAT,
utc_start TEXT,
duration_sec INT,
name TEXT,
creator TEXT,
mode TEXT,
az FLOAT,
alt FLOAT,
ra FLOAT,
dec FLOAT,
freq_res FLOAT,
time_res FLOAT,
grb TEXT,
target_name TEXT
calibrator BOOL,
cal_obs INT,
archived BOOL,
FOREIGN KEY(grb) REFERENCES grb(name),
FOREIGN KEY(cal_obs) REFERENCES observation(obs_id)
);

CREATE TABLE processing
(
id INT PRIMARY KEY,
submission_time TEXT,
script TEXT,
args TEXT,
obs_id INT,
success BOOL,
batch_file TEXT,
stderr TEXT,
stdout TEXT,
output_files TEXT,
FOREIGN KEY(obs_id) REFERENCES observation(osb_id)
);
"""

def main():
    conn = sqlite3.connect(dbfile)
    cur = conn.cursor()
    for cmd in schema.split(';'):
        print cmd + ';'
        cur.execute(cmd)
    conn.close()

if __name__ == '__main__':
    main()
