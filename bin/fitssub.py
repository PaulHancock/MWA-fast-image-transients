from __future__ import print_function
from astropy.io import fits as pyfits

import sys,os
from datetime import datetime, timedelta


def get_time_from_header(hdu):
    """ Make a datetime object from a fits header.
    Include fractional seconds in the returned value
    """
    tstring1 = hdu[0].header['DATE-OBS']
    t1 = datetime.strptime(tstring1, '%Y-%m-%dT%H:%M:%S.%f')
    return t1



file1,file2,out=sys.argv[1:4]
print("combining {0}-{1}={2}".format(file1,file2,out))

if not os.path.exists(file1):
    print("can't find {0}".format(file1))
if not os.path.exists(file2):
    print("can't find {0}".format(file2))

fits1 = pyfits.open(file1)
fits2 = pyfits.open(file2)

if fits1[0].data.shape != fits2[0].data.shape:
    print("incompatible file sizes {0} and {1}".format(fits1[0].data.shape,fits2[0].data.shape))
    sys.exit(1)

fits1[0].data-=fits2[0].data

# now update the date-obs in the header 
# 2017-08-27T22:09:27.4
t1 = get_time_from_header(fits1)
t2 = get_time_from_header(fits2)
mid = t1 + (t2-t1)/2

fits1[0].header['DATE-OBS'] = mid.strftime(format='%Y-%m-%dT%H:%M:%S.%f')

fits1[0].header['HISTORY'] = "Diff image"
fits1[0].header['HISTORY'] = "{0} - {1} = this file".format(file1, file2)
fits1.writeto(out,overwrite=True)
