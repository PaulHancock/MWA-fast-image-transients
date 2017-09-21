from astropy.io import fits as pyfits

import sys,os

file1,file2,out=sys.argv[1:4]
print "combining {0}-{1}={2}".format(file1,file2,out)

if not os.path.exists(file1):
    print "can't find {0}".format(file1)
if not os.path.exists(file2):
    print "can't find {0}".format(file2)

fits1 = pyfits.open(file1)
fits2 = pyfits.open(file2)

if fits1[0].data.shape != fits2[0].data.shape:
    print "incompatible file sizes {0} and {1}".format(fits1[0].data.shape,fits2[0].data.shape)
    sys.exit()
fits1[0].data-=fits2[0].data
fits1.writeto(out,clobber=True)
