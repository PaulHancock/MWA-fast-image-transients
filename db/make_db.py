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
projectid TEXT,
lst_deg FLOAT,
starttime TEXT,
duration_sec INT,
obsname TEXT,
creator TEXT,
azimuth_pointing FLOAT,
elevation_pointing FLOAT,
ra_pointing FLOAT,
dec_pointing FLOAT,
freq_res FLOAT,
int_time FLOAT,
grb TEXT,
calibration BOOL,
cal_obs_id INT,
calibrators TEXT,
archived BOOL,
nfiles INT,
status TEXT,
FOREIGN KEY(grb) REFERENCES grb(name),
FOREIGN KEY(cal_obs_id) REFERENCES observation(obs_id)
);

CREATE TABLE processing
(
job_id INT PRIMARY KEY,
submission_time INT,
task TEXT,
start_time INT,
end_time INT,
obs_id INT,
status TEXT,
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
