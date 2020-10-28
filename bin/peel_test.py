#! /usr/bin/env python
from __future__ import print_function

import astropy
from astropy.io import fits
import numpy as np

from AegeanTools import regions

# define MWA position


# Define constants
SUN_IN_MAIN_LOBE = 3 
SUN_IN_SIDE_LOBE = 2
SUN_ELSEWHERE = 1 
SUN_BELOW_HORIZON = 0

def where_is_Sun(obstime, meta):
    """
    Determin if the sun is within the primary beam main lobe or secondary lobe

    parameters
    ----------
    obstime : float or timedate
      The time at which the observation was made

    meta : 
      Meta data for the observation (incl freq, and beam former settings)
      
    Return
    ------
    location : str
      Location of the Sun.
    """
    # Calculate sun eleveation
    if el < 0:
        return SUN_BELOW_HORIZON

    # calculate beam in the direction of the sun
    if beam < 0.1:
        return SUN_ELSEWHERE
    
    # calculate offset between sun and pointing direction
    if offset < 20:
        return SUN_IN_MAIN_LOBE

    return SUN_IN_SIDE_LOBE


def within_GLEAM_footprint(pos, footprint=None):
    """
    Determine if a give pointing direction is within the GLEAM footprint

    parameters
    ----------
    pos : (ra,dec)
      The pointing direction in degrees.

    footprint : AegeanTools.regions.Region or str
      The GLEAM footprint

    Return
    ------
    within : bool
      obvious
    """
    # check if footprint is string or Region obj
    region = regions.Region.load(footprint)
    return region.sky_within(pos[0],pos[1], degin=True)


if __name__ == "__main__":
    loc = where_is_sun(obstime = time,
                       mete = metadata)
    print("The Sun is {0}".format(['below horizon', 'elsewhere in the sky','in a sidelobe','in the main lobe'][loc]))

    within = within_GLEAM_footprint(pos = (ra,dec),
                                    footprint = 'GLEAM.mim')
    if within:
        print("Infield calibration")
    else:
        print("Reference calibration")
