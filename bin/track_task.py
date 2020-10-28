#! python
from __future__ import print_function

__author__ = "PaulHancock"

import sqlite3
import sys

db='db/MWA-GRB.sqlite'

def queue_job(job_id, submission_time, obs_id, batch_file, stderr, stdout, task):
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.execute("""INSERT INTO processing
    ( job_id, submission_time, obs_id, batch_file, stderr, stdout, task, status)
    VALUES ( ?,?,?,?,?,?,?, 'queued')
    """, (job_id, submission_time, obs_id, batch_file, stderr, stdout, task))
    conn.commit()
    conn.close()


def start_job(job_id, start_time):
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.execute("""UPDATE processing SET status='started', start_time=? WHERE job_id =?""", (start_time, job_id))
    conn.commit()
    conn.close()


def finish_job(job_id, end_time):
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.execute("""UPDATE processing SET status='finished', end_time=? WHERE job_id =?""", (end_time, job_id))
    conn.commit()
    conn.close()


def fail_job(job_id, time):
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.execute("""UPDATE processing SET status='failed', end_time=? WHERE job_id =?""", (time, job_id))
    conn.commit()
    conn.close()


def require(args, reqlist):
    """
    Determine if the the given requirements are met
    ie that the attributes in the reqlist are not None.
    """
    for r in reqlist:
        if not getattr(args, r):
            print("Directive {0} requires argument {1}".format(args.directive, r))
            sys.exit()
    return True

if __name__ == "__main__":

    import argparse
    ps = argparse.ArgumentParser(description='track tasks')
    ps.add_argument('directive', type=str, help='Directive', default=None)
    ps.add_argument('--jobid', type=int, help='Job id from slurm', default=None)
    ps.add_argument('--task', type=str, help='task being run', default=None)
    ps.add_argument('--submission_time', type=int, help="submission time", default=None)
    ps.add_argument('--start_time', type=int, help='job start time', default=None)
    ps.add_argument('--finish_time', type=int, help='job finish time', default=None)
    ps.add_argument('--batch_file', type=str, help='batch file name', default=None)
    ps.add_argument('--obs_id', type=int, help='observation id', default=None)
    ps.add_argument('--stderr', type=str, help='standard error log', default=None)
    ps.add_argument('--stdout', type=str, help='standard out log', default=None)

    args = ps.parse_args()

    if args.directive.lower() == 'queue':
        require(args, ['jobid', 'submission_time', 'obs_id', 'batch_file', 'stderr', 'stdout', 'task'])
        queue_job(args.jobid, args.submission_time, args.obs_id, args.batch_file, args.stderr, args.stdout, args.task)
    elif args.directive.lower() == 'start':
        require(args, ['jobid', 'start_time'])
        start_job(args.jobid, args.start_time)
    elif args.directive.lower() == 'finish':
        require(args, ['jobid', 'finish_time'])
        finish_job(args.jobid, args.finish_time)
    elif args.directive.lower() == 'fail':
        require(args, ['jobid', 'finish_time'])
        fail_job(args.jobid, args.finish_time)
    else:
        print("I don't know what you are asking please include a queue/start/finish/fail directive")
