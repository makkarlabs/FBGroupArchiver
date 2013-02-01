--Table structure for table `posts`

CREATE TABLE IF NOT EXISTS posts (
   id int AUTO_INCREMENT NOT NULL,
   author_name varchar(100) NOT NULL,
   author_id text NOT NULL,
   message text NOT NULL,
   likes_count int DEFAULT NULL,		
   created_time timestamp NOT NULL,
   updated_time timestamp NOT NULL,
   comments_count int DEFAULT NULL,
   post_id varchar(255) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);


--Table structure for table `links`

CREATE TABLE IF NOT EXISTS links (
  url varchar(255) NOT NULL UNIQUE,
  title text NOT NULL,
  post_id varchar(255) NOT NULL,
  id int NOT NULL AUTO_INCREMENT,
  description text NOT NULL,
  PRIMARY KEY (id)
);

--Table structure for table `likes`
CREATE TABLE IF NOT EXISTS likes (
post_id varchar(255) NOT NULL,
user_id varchar(255) NOT NULL,
created_at timestamp NOT NULL,
id int NOT NULL AUTO_INCREMENT,
PRIMARY KEY (id)
);

--Table structure for table `comments`
CREATE TABLE IF NOT EXISTS comments (
comment_id varchar(255) NOT NULL UNIQUE,
post_id varchar(255) NOT NULL,
user_id varchar(255) NOT NULL,
comment_text text NOT NULL,
comment_length int NOT NULL,
number_of_likes int DEFAULT 0,
created_at timestamp NOT NULL,
updated_at timestamp NOT NULL,
id int AUTO_INCREMENT NOT NULL,
PRIMARY KEY (id)
);

--Table structure for table `user`
CREATE TABLE IF NOT EXISTS user (
user_id varchar(255) NOT NULL UNIQUE,
active boolean DEFAULT 0, 
firstname varchar(255) NOT NULL,
middlename varchar(255) DEFAULT NULL,
lastname varchar(255) DEFAULT NULL,
gender varchar(1) DEFAULT NULL,
location varchar(255) DEFAULT NULL,
link text DEFAULT NULL,
username varchar(255) NOT NULL,
id int AUTO_INCREMENT NOT NULL,
PRIMARY KEY(id)
);

--Table structure for table `user_points`
CREATE TABLE IF NOT EXISTS user_points (
id int AUTO_INCREMENT NOT NULL,
user_id varchar(255) NOT NULL UNIQUE,
comments_o_count int NOT NULL DEFAULT 0,
comments_u_count int NOT NULL DEFAULT 0,
likes_o_count int NOT NULL DEFAULT 0,
likes_u_count int NOT NULL DEFAULT 0,
post_points int NOT NULL DEFAULT 0,
xtra_points int NOT NULL DEFAULT 0,
total_points int NOT NULL DEFAULT 0,
last_updated_time timestamp NOT NULL,
PRIMARY KEY(id)
);

