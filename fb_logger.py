import urllib2
import urllib
import re
import ConfigParser
import json
import MySQLdb
import logging
import traceback
from datetime import datetime
from datetime import timedelta
import iso8601

def sane(text, quotes=True):
    if(quotes):
        return text.encode('ascii','ignore').replace('"','')
    else:
        return text.encode('ascii','ignore')

def parse_date(datestring):
    return iso8601.parse_date(datestring).strftime('%Y-%m-%d %H:%M:%S')


class FbGroupArchiver:

    def __init__(self, config_filename):
        print "Update Started...."
        self.config = ConfigParser.ConfigParser()
        try:
            self.config.read(config_filename)
        except:
            print 'Config file'+str(config_filename)+' cannot be read'
            return
        config = self.config
        self.start_time = datetime.now()
        self.prev_update = self.start_time - timedelta(minutes=int(config.get('cron','interval')))

        self.db = MySQLdb.connect(user=config.get('db','user'), passwd=config.get('db','password'), db=config.get('db','name'))
        self.cursor = self.db.cursor()
        logging.basicConfig(filename=config.get('logging','infolog'), level=logging.INFO)

    def process_data(self, group_url=None):
        cursor = self.cursor
        config = self.config
        if(group_url == None):
            group_url = config.get('group','url')
        data = urllib2.urlopen(group_url).read()
        jsondata = json.loads(data)
        for i,post in enumerate(jsondata['data']):
            try:
                code = self.update_post(post)
                #print code
            except Exception, err:
                print 'Some error'
                logging.error(str(datetime.now())+" "+str(err))
                traceback.print_exc(file = open(config.get('logging','errorlog'),'a'))

        self.db.commit()
        self.db.close()
        duration = datetime.now() - self.start_time
        print duration
        logging.info(str(datetime.now())+' Archiving Complete for page: '+ group_url + ' in ' + str(duration))

    def update_post(self, post):
        print '.',
        config = self.config
        cursor = self.cursor
        post_id = post.get('id').rsplit('_',1)[1]
        message = post.get('message')
        created_on = parse_date(post.get('created_time'))
        updated_on = parse_date(post.get('updated_time'))
        author_name = sane(post.get('from').get('name'))
        author_id = post.get('from').get('id')
        if(message != None):
            message = sane(message)
            comments_count = 0
            likes_count = 0
            
            if post.get('comments') != None:
                comments_count = post.get('comments').get('count')
                if post.get('comments').get('data') != None:
                    for comment in post.get('comments').get('data'):
                        self.update_comment(author_id, comment)
            
            if post.get('likes') != None:
                likes_count = post.get('likes').get('count')
                if post.get('likes').get('data') != None:
                    for like in post.get('likes').get('data'):
                        self.update_like(author_id, post_id, like)
            
            cursor.execute("""SELECT InsertPost(%s, %s, %s, %s, %s, %s, %s, %s)""", (author_name, author_id, message, likes_count, comments_count, created_on, updated_on, post_id))
            code = cursor.fetchone()
            self.update_link(code, post)
            return code

    def update_link(self, code, post):
        # code[0] indicates the number of affected rows, 
        #if its 1 -> successful insert, if not the post already exists in the Db
        config = self.config
        controlchar_regex = re.compile(r'[\n\r\t]')
        author_name = sane(post.get('from').get('name'))
        post_id = post.get('id')
        message = post.get('message')
        title = ' '
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
            # uncomment if you want to post links to kippt
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
                   # uncomment if you want to post to kippt
                   r = self.post_to_kippt(values)
                   self.post_link(r, post_id)
           except Exception, err:
               logging.error(str(datetime.now())+" "+str(err))
               traceback.print_exc(file = open(config.get('logging','errorlog'),'a'))



    def update_comment(self, author_id, comment):
        cursor = self.cursor
        com_id = comment.get('id')
        from_id = comment.get('from').get('id')
        text = sane(comment.get('message'))
        created_time = parse_date(comment.get('created_time'))
        likes_count = comment.get('likes')
        post_id = com_id.split('_')[0] + '_' + com_id.split('_')[1]
        cursor.execute("""SELECT InsertComment(%s, %s, %s, %s, %s, %s, %s, %s) """, (com_id, post_id, from_id, text, len(re.findall(r'\w+', text)), likes_count, created_time, author_id ))

    def update_like(self, author_id, post_id, like):
        cursor = self.cursor
        user_id = like.get('id')
        cursor.execute("""SELECT InsertLike(%s, %s, %s, %s) """,(post_id, user_id, self.prev_update, author_id))
            
    def post_to_kippt(self, values):
        #print values
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
