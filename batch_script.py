import urllib
import urllib2
import json
import ConfigParser
import sys

from fb_logger import FbGroupArchiver

def index():
    config = ConfigParser.ConfigParser()
    if(len(sys.argv)>2):
        group_url = sys.argv[2]
    elif(len(sys.argv)>1):
        config.read(sys.argv[1])
        group_url = config.get('group','url')
    else:
        print 'Usage: python batch_script.py [Config file name] [group page url(optional)]]'
        return
    data = urllib2.urlopen(group_url).read()
    jsondata = json.loads(data)
    while(group_url is not None):
        FbGroupArchiver(sys.argv[1]).process_data(group_url)
        data = urllib2.urlopen(group_url).read()
        jsondata = json.loads(data)
        group_url = jsondata.get('paging').get('next')
        print group_url
if __name__ == "__main__":
    index()

