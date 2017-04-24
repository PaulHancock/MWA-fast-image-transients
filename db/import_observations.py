import sqlite3
from astropy.io import ascii


headers = ['obsid','UTC','duration','obsname','projectid','RA','Dec',
'sun_elevation','sun_pointing_distance','jupiter_pointing_distance','moon_pointing_distance','sky_temp',
'calibration','calibrators','gridpoint_name','gridpoint_number','gain_control_type','gain_control_value']
headers.extend(['junk_{0}'.format(i) for i in range(24)])

filename = 'observations_24Apr2017.csv'
db = 'MWA-GRB.sqlite'


def main():
    tab = ascii.read(filename, names=headers)
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    for row in tab:
        cur.execute("""INSERT OR REPLACE INTO observation
( obs_id, project, utc_start, duration_sec, name, ra, dec, calibrator )
VALUES (?,?,?,?,?,?,?,?)
""", (row['obsid'], row['projectid'], row['UTC'], row['duration'], row['obsname'], row['RA'], row['Dec'], row['calibration']))
    conn.commit()
    conn.close()

if __name__=='__main__':
    main()
