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

def sane(self, text, quotes=True):
    if(quotes):
        return text.encode('ascii','ignore').replace('"','')
    else
        return text.encode('ascii','ignore')

def parse_date(self, datestring):
    return iso8601.parse_date(datestring).strftime('%Y-%m-%d %H:%M:%S')


class FbGroupArchiver:

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
        if(group_url == None):
            group_url = config.get('group','url')
        data = urllib2.urlopen(group_url).read()
        jsondata = json.loads(data)
        for i,post in enumerate(jsondata['data']):
            try:
                print post.get('id')
                post_id = post.get('id').rsplit('_',1)[1]
                message = post.get('message')
                created_on = parse_date(post.get('created_time'))
                updated_on = parse_date(post.get('updated_time'))
		        author_name = sane(post.get('from').get('name'))
                author_id = post.get('from').get('id')
                if(message != None):
                    message = sane(message)
                    comments_count = None
                    likes_count = None
                    title = ''
                    if(post.get('comments') != None):
                        comments_count = post.get('comments').get('count')
                    #
                    if(post.get('likes') != None):
                        likes_count = post.get('likes').get('count')
                    # Do the DB part here
                    cursor.execute("""SELECT InsertPost(%s, %s, %s, %s, %s, %s, %s, %s)""", (author_name, author_id, message, likes_count, comments_count, created_on, updated_on, post_id))
                    code = cursor.fetchone()
                    # code[0] indicates the number of affected rows, 
                    #if its 1 -> successful insert, if not the post already exists in the Db
                    if(code[0] == 1 and post.get('link') !=  None):
                        link = sane(post.get('link'), False)
                        if(post.get('name') != None):
                            title = controlchar_regex.sub(' ',sane(post.get('name')))
                        if(post.get('description') != None):
                            description = sane(post.get('description'))
                            description = controlchar_regex.sub(' ',description) + ' - ' + author_name
                        else:
                            description = controlchar_regex.sub(' ',message) + ' - ' + author_name
                
                        # Build the JSON
                        values = '{"url": "'+link+'" , "list":"'+config.get('kippt','listuri')+'", "title":"'+title+'", "notes":"'+description+ '"}'
                        r = self.post_to_kippt(values)
                        self.post_link(r, post_id)

                    elif(code[0] == 1):
                       
                       # make this regex better if you want
                       try:
                           description = sane(post.get('message'))
                           description = controlchar_regex.sub(' ',description)
                           urls =  re.findall("(?P<url>https?://[^\s]+)", description)
                           for url in urls:
                               description = description.replace(url, '')
                           description = description  + ' - ' + author_name

                           for url in urls:
                               # Build the JSON
                               values = '{"url": "'+url+'" , "list": "'+config.get('kippt','listuri')+'", "notes":"'+description+'"}' 
                               r = self.post_to_kippt(values)
                               self.post_link(r, post_id)
                       except Exception, err:
                           logging.error(str(datetime.now())+" "+str(err))
                           traceback.print_exc(file = open(config.get('logging','errorlog'),'a'))
            except Exception, err:
                print 'Some error'
                logging.error(str(datetime.now())+" "+str(err))
                traceback.print_exc(file = open(config.get('logging','errorlog'),'a'))
        print "Archiving Complete!"
        logging.info(str(datetime.now())+' Archiving Complete for page: '+group_url)

    def post_to_kippt(self, values):
        print values
        config = self.config
        req = urllib2.Request(config.get('kippt','url'),values)
        req.add_header('X-Kippt-Username', config.get('kippt','username'))
        req.add_header('X-Kippt-API-Token', config.get('kippt','apitoken'))
        r = urllib2.urlopen(req)
        return r.read()                                                                   

    def post_link(self, response, post_id):
        cursor = self.cursor
        resp_data = json.loads(response)
        resp_url = sane(resp_data.get('url'))
        resp_title = sane(resp_data.get('title'))
        resp_notes = sane(resp_data.get('notes')) 
        cursor.execute("""SELECT InsertLink(%s, %s, %s, %s) """,(resp_url, resp_title, resp_notes, post_id ))
