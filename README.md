# Facebook Group Archiver
 

This app helps us archive all posts from a facebook group along with its metadata and generate analytics to improve user involvement.

## Scripts

### fb_logger.py

* Archives posts, comments, likes from the group
* Parses out links from posts and sends it to kippt

### db/dbcreate.sql

* Create table statements for tables - posts, comments, likes, links, user, user_points
* Functions to insert into / update  tables - posts, comments, likes, links
* Functions to create users and calculate points for each user - user, user_points

### cronjob.py

* Should run every 'few' minutes to update the database
* Basically calls fb_logger.py along with the facebook graph api url 

### batchscript.py

* Fetches all of the posts in the group since its beginning - for first time update.

### insert_users.py

* This script is run for the first time to update User db with group members
* The Facebook API only returns ~5000 members, so usercron.py ensures daily updates of the User table

### usercron.py
* This cron is run daily to update the User table
* Fetches top 50 users(recently added) from the facebook group member list and adds them to the user table
* To cope for the old missed out users because of ~5000 limit of the API it finds users in user_points not in user table, and populates their details

## Configuration

### config/default_properties.cfg

* facebook group links - graph api url and members list fql url
* location of info log and error log files
* mysql database configuration
* kippt configuration
* cronjob interval (in minutes)

## Commands 

### cronjob

    python cronjob.py config/<properties_filename>.cfg

### usercron

    python usercron.py config/<properties_filename>.cfg

### insert_users

    python insert_users.py config/<properties_filename>.cfg

### batchscript

    python batchscript.py config/<properties_filename>.cfg [facebook group graph api url(optional)]
