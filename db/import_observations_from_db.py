import urllib
import urllib2
import json

import sqlite3

# Append the service name to this base URL, eg 'con', 'obs', etc.
BASEURL = 'http://mwa-metadata01.pawsey.org.au/metadata/'
dbfile = 'MWA-GRB.sqlite'

# Function to call a JSON web service and return a dictionary:

def getmeta(service='obs', params=None):
  """
  Given a JSON web service ('obs', find, or 'con') and a set of parameters as
  a Python dictionary, return a Python dictionary containing the result.
  """
  if params:
    data = urllib.urlencode(params)  # Turn the dictionary into a string with encoded 'name=value' pairs
  else:
    data = ''
  # Validate the service name
  if service.strip().lower() in ['obs', 'find', 'con']:
    service = service.strip().lower()
  else:
    print "invalid service name: %s" % service
    return
  # Get the data
  try:
    print BASEURL + service + '?' + data
    result = json.load(urllib2.urlopen(BASEURL + service + '?' + data))
  except urllib2.HTTPError as error:
    print "HTTP error from server: code=%d, response:\n %s" % (error.code, error.read())
    return
  except urllib2.URLError as error:
    print "URL or network error: %s" % error.reason
    return
  # Return the result dictionary
  return result


def copy_obs_info(obsid, cur):
    cur.execute("SELECT count(*) FROM observation WHERE obs_id =?",(obsid,))
    if cur.fetchone()[0] >0:
        print "already imported", obsid
        return
    meta = getmeta(service='obs', params={'obs_id':obsid})
    metadata = meta['metadata']
    cur.execute("""
INSERT OR REPLACE INTO observation
(obs_id, projectid,  lst_deg, starttime, duration_sec, obsname, creator,
azimuth_pointing, elevation_pointing, ra_pointing, dec_pointing,
freq_res, int_time, grb, 
calibration, cal_obs_id, calibrators,
archived
)
VALUES (?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?,?);
""", (
obsid, meta['projectid'], metadata['local_sidereal_time_deg'], meta['starttime'], meta['stoptime']-meta['starttime'], meta['obsname'], meta['creator'],
metadata['azimuth_pointing'], metadata['elevation_pointing'], metadata['ra_pointing'], metadata['dec_pointing'],
meta['freq_res'], meta['int_time'], None,
metadata['calibration'], None, metadata['calibrators'],
False))
    

if __name__ == "__main__":
    conn = sqlite3.connect(dbfile)
    cur = conn.cursor()

    obsdata = getmeta(service='find', params={'projectid':'D0009'}) #'limit':10
    for obs in obsdata:
        obs_id = obs[0]
        copy_obs_info(obs_id, cur)
        conn.commit()
    conn.close()
#obsinfo1 = getmeta(service='obs', params={'obs_id':starttime})
#obsinfo2 = getmeta(service='obs', params={'filename':fname})

#coninfo1 = getmeta(service='con', params={'obs_id':starttime})
#coninfo2 = getmeta(service='con', params={'filename':fname})

#olist = getmeta(service='find', params={'mintime':1097836168, 'maxtime':1097840480, 'obsname':'3C444%'})
