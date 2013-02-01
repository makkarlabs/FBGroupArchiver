import sys

from fb_group_sync import FbGroupArchiver

try:
    FbGroupArchiver(sys.argv[1]).process_data()
except Exception, err:
    print sys.argv[0]
    print 'Pass config file as command line argument'
    print sys.argv[1]
    print err
