# CONSTANTS THAT ARE ACCESSED BY GQUERIES HAVE TO BE PUT IN:
# app/models/rubel/functions/constants.rb

MWH_TO_GJ = 3.6
MONTHS_PER_YEAR = 12.0
HOURS_PER_YEAR = 8760.0
SECS_PER_HOUR = 3600.0
SECS_PER_YEAR = SECS_PER_HOUR * HOURS_PER_YEAR
KG_PER_TONNE = 1000
LITER_PER_BARREL = 159
MJ_TO_MHW = 3600
MJ_PER_KWH = 3.6
MJ_PER_MWH = 3600
BILLIONS = 10.0**9
MJ_TO_PJ = BILLIONS
MILLIONS = 10.0**6
THOUSANDS = 1000.0
#NIL = nil if !defined?(NIL)
EURO_SIGN = '&euro;'

# 2011-12-09 GQL grammar does not allow "." inside V(...; ___ ).
# So it is impossible to use floats, e.g. V(...; demand * 2.5)
# or V(...; demand ** 2/3). (2/3 would return 0, because they are ints)
#
# Until we properly extend the GQL grammar, we can use the following
# work around:
# V(...; demand * 2 + FLOAT_HACK/2)
# V(...; demand ** 2*FLOAT_HACK/3)
FLOAT_HACK = 1.0

