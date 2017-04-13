import astropy
from astropy.io import fits
from astropy.wcs import WCS
from time import gmtime, strftime
import numpy as np
import os

nfreqs = 768
ntimes = 232
for t in range(ntimes):
    fname = '1102604896-sm-t{0:04d}-{1:04d}-image.fits'.format(t,0)
    base = fits.open(fname)
    data = np.empty( (1,768,320,320))
    print strftime("%Y-%m-%d %H:%M:%S", gmtime())
    outname = '1102604896-sm-t{0:04d}-all-image.fits'.format(t)
    if os.path.exists(outname):
        continue
    for f in range(nfreqs):
        fname = '1102604896-sm-t{0:04d}-{1:04d}-image.fits'.format(t,f)
        data[0,f,:,:] = fits.getdata(fname)
    base[0].data = np.float32(data)
    base.writeto(outname)
    print outname
