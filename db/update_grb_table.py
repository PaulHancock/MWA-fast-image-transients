#! python

import re
import sqlite3
import sys
import urllib

__author__ = 'PaulHancock'

dbfile = 'MWA-GRB.sqlite'

fermi_grb_site = "https://gcn.gsfc.nasa.gov/other/{0}.fermi"
swift_grb_site = "https://gcn.gsfc.nasa.gov/other/{0}.swift"

divider = re.compile('^/*$')


def page_to_reports(html):
    """
    Parse one of the GRB pages into a list of reports
    :param html:
    :return:
    """
    reports = []
    report = []
    for line in html.readlines():
        if divider.match(line.strip()):
            if len(report) > 0:
                reports.append(report)
                report = []
                continue
        else:
            report.append(line)
    if len(report) > 0:
        reports.append(report)
    return reports


def report_to_fields(report, fields=None):
    """
    Take a single report and convert the KEY: value
    lines into a dict of key-value pairs.

    Ignore any lines that don't have a colon in them.
    :param report: A list of text lines.
    :param fields: If not None, then update an existing dict.
    :return:
    """
    if fields is None:
        fields = {}
    for r in report:
        if ':' in r:
            key, val = r.split(':', 1)
            if key == 'COMMENTS':
                if key in fields:
                    fields[key] += (val.strip())
                    continue
            fields[key] = val.strip()
    return fields


def get_last_report(trigger_id, mission='fermi'):
    """
    Return the last report on the summary page for a given trigger_id
    :param trigger_id:
    :param mission: 'fermi' or 'swift'
    :return:
    """
    if 'fermi' in mission:
        site = fermi_grb_site
    elif 'swift' in mission:
        site = swift_grb_site
    else:
        print "Uknown mission {0}".format(mission)
        sys.exit()

    html = urllib.urlopen(site.format(trigger_id))
    rs = page_to_reports(html)
    fs = report_to_fields(rs[-1])
    return fs


def get_accumulated_report(trigger_id, mission='fermi'):
    """
    Return the last value for each keyword on the summary page for a given trigger_id
    :param trigger_id:
    :param mission: 'fermi' or 'swift'
    :return:
    """
    if 'fermi' in mission:
        site = fermi_grb_site
    elif 'swift' in mission:
        site = swift_grb_site
    else:
        print "Uknown mission {0}".format(mission)
        sys.exit()
    html = urllib.urlopen(site.format(trigger_id))
    rs = page_to_reports(html)
    fs = None
    for r in rs:
        fs = report_to_fields(r, fs)
    return fs


def report_to_row(f, db, mission='fermi'):
    # position and err in degrees
    print f['GRB_RA'], f['GRB_DEC'], f['GRB_ERROR'], f['MOST_LIKELY'], f['TRIGGER_NUM'], f['GRB_DATE']
    best_ra = float(f['GRB_RA'].split()[0][:-1])
    best_dec = float(f['GRB_DEC'].split()[0][:-1])
    pos_err = float(f['GRB_ERROR'].split()[0])
    if 'min' in f['GRB_ERROR']:
        pos_err /= 60
    is_a_grb = 'GRB' in f['MOST_LIKELY']
    name = 'GRB'+f['GRB_DATE'].split()[-1].replace('/','') + 'A'

    if 'short grb' in f['COMMENTS'].lower():
        grb_type = 'short'
    elif 'long grb' in f['COMMENTS'].lower():
        grb_type = 'long'
    else:
        grb_type = 'unknown'

    if 'fermi' in mission:
        fermi_trigger_id = f['TRIGGER_NUM']
        fermi_url = fermi_grb_site.format(fermi_trigger_id)
        swift_trigger_id = None
        swift_url = None
        best_pos_ref = 'FERMI'

    elif 'swift' in mission:
        swift_trigger_id = f['TRIGGER_NUM']
        swift_url = swift_grb_site.format(swift_trigger_id)
        fermi_trigger_id = None
        fermi_url = None
        best_pos_ref = 'SWIFT'
        if 'This is a GRB.' in f['COMMENTS']:
            is_a_grb = True
        # if instead of elif since the notices may reassign this as a non-grb
        if 'This is not a GRB.' in f['COMMENTS']:
            is_a_grb = False
    else:
        print "Unknown mission {0}".format(mission)
        sys.exit()

    db.execute("""
    INSERT INTO grb (name, fermi_trigger_id, fermi_url, swift_trigger_id,
swift_url, best_ra, best_dec, pos_err, best_pos_ref, is_a_grb, type )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (name, fermi_trigger_id, fermi_url, swift_trigger_id,
swift_url, best_ra, best_dec, pos_err, best_pos_ref, is_a_grb, grb_type))
    return


def validate(f):
    for k in ['GRB_RA', 'GRB_DEC', 'GRB_ERROR', 'MOST_LIKELY', 'TRIGGER_NUM', 'GRB_DATE', 'COMMENTS']:
        if not k in f:
            return False
    return True


def update_grb_table(last_trigger=None):
    """
    Search the observations table for GRBs that have been observed
    and update the grb table with the required information.
    :param last_trigger:
    :return:
    """
    conn = sqlite3.connect(dbfile)
    cur = conn.cursor()

    # select the not-yet processed triggers
    ids = zip(*cur.execute("""SELECT obsname
    FROM observation WHERE calibration=0
    AND obsname NOT IN (SELECT fermi_trigger_id FROM grb)
    GROUP BY obsname""").fetchall())[0]
    # TODO: test for swift triggers
    for i, id in enumerate(ids):
        mission = 'fermi'
        if 'CORR_MODE' in id:
            continue
        if 'GRB' in id:
            # eg GRB467353077_145
            id = id[3:-4]
        if 'GCN' in id:
            id = id[3:]
            mission = 'swift'
        r = get_accumulated_report(id, mission)
        valid = validate(r)
        print id, "{0}/{1}".format(i, len(ids)), valid
        if valid:
            report_to_row(r, cur, mission)

    conn.commit()
    conn.close()

if __name__ == "__main__":
    update_grb_table()
    # r = get_last_report(515881797)
    # for k in r:
    #     print k, '=', r[k]
    # conn = sqlite3.connect(dbfile)
    # cur = conn.cursor()
    # fermi_report_to_row(r, cur)
    # conn.commit()
    # conn.close()