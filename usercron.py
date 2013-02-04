#This cron is run daily to update the User table
#It does 2 things:
#1. Fetches top 50 users(recently added) from the facebook group member list
#   and adds them to the user table
#2. To cope for the old missed out users because of ~5000 limit of the API
#   it finds users in user_points not in user table, and populates their details

import urllib2
import urllib
import re
import ConfigParser
import json
import MySQLdb
import logging
import traceback
from datetime import datetime
import iso8601
import sys

def sane(text, quotes=True):
    if(quotes):
        return text.encode('ascii','ignore').replace('"','')
    else:
        return text.encode('ascii','ignore')

def parse_date(datestring):
    return iso8601.parse_date(datestring).strftime('%Y-%m-%d %H:%M:%S')


class UserArchiver:

    def __init__(self, config_filename):
        self.config = ConfigParser.ConfigParser()
        try:
            self.config.read(config_filename)
        except:
            print 'Config file'+str(config_filename)+' cannot be read'
            return
        config = self.config
        self.db = MySQLdb.connect(user=config.get('db','user'), passwd=config.get('db','password'), db=config.get('db','name'))
        self.cursor = self.db.cursor()
        logging.basicConfig(filename=config.get('logging','infolog'), level=logging.INFO)

    def process_data(self, group_url=None):
        controlchar_regex = re.compile(r'[\n\r\t]')
        cursor = self.cursor
        config = self.config

        #Case 1: Recent group members from the API
        if(group_url == None):
            group_url = config.get('group','url_user')+"%20Limit%2050"
        data = urllib2.urlopen(group_url).read()
        jsondata = json.loads(data)
        for i,user in enumerate(jsondata['data']):
            try:
                self.update_user(user) 
            except Exception, err:
                print 'Some error'
                logging.error(str(datetime.now())+" "+str(err))
                traceback.print_exc(file = open(config.get('logging','errorlog'),'a'))
        self.db.commit()
        logging.info(str(datetime.now())+' User Archiving Complete for page: '+group_url)
        
        #Case 2: Users in user_points Not in User
        cursor = self.cursor
        cursor.execute("SELECT user_points.user_id FROM user_points WHERE user_points.user_id NOT IN (SELECT user.user_id FROM user)")
        rows = cursor.fetchall()
        n = len(rows)
        print n
        for row in rows:
            try:
                user_url = "http://graph.facebook.com/"+row[0]
                data = urllib2.urlopen(user_url).read()
                user_json = json.loads(data)
                self.update_user(user_json)
            except Exception, err:
                print 'Some error'
                logging.error(str(datetime.now())+" "+str(err))
                traceback.print_exc(file = open(config.get('logging','errorlog'),'a'))

        self.db.commit()
        self.db.close()
        logging.info(str(datetime.now())+' User Archiving Complete for '+str(n)+' users not in user but in user_points')
        print "Archiving Complete!"


    def update_user(self, user):
        cursor = self.cursor
        user_id = user.get('uid')
        firstname = sane(user.get('first_name'))
        middlename = ""
        if user.get('middle_name') is not None:
            middlename = sane(user.get('middle_name'))
        lastname = sane(user.get('last_name'))
        gender = ""
        if user.get('sex') != "" and user.get('sex') is not None:
            gender = user.get('sex')[0]
        location = ""
        current_location = user.get('current_location')
        if current_location is not None:
            location = current_location.get('city')+', '+current_location('state')+', '+current_location.get('country')
        link = user.get('profile_url')
        if link is None:
            link = ""
        active = 0 
        username = user.get('username')
        cursor.execute("""SELECT InsertUser(%s, %s, %s, %s, %s, %s, %s, %s, %s) """, (user_id, active, firstname, middlename, lastname, gender, location, link, username))

try:
    UserArchiver(sys.argv[1]).process_data()    
except Exception, err:
    print sys.argv[0]
    print 'Pass config file as command line argument'
    print sys.argv[1]
    print err
                
