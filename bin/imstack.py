from __future__ import print_function
import astropy
from astropy.io import fits
import numpy as np
import sys

__author__ = 'Paul Hancock'


def stack(files, outname):
    base = fits.open(files[0])
    data = []
    for f in files[1:]:
        data.append(fits.getdata(f))
    base[0].data = np.array(data, dtype=np.float32)
    base.writeto(outname, clobber=True)


if __name__ == "__main__":
    import argparse
    ps = argparse.ArgumentParser(description='Stack images')
    ps.add_argument('--files', type=str, nargs='+', metavar='file', default=[])
    ps.add_argument('--out', type=str, help='output file', default=None)

    args = ps.parse_args()
    if len(args.files) < 2:
        print("Require at least two input files")
        ps.print_help()
        sys.exit(1)
    stack(args.files, args.out)
