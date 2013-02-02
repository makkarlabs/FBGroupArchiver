--Table structure for posts
CREATE TABLE IF NOT EXISTS posts (
   id int AUTO_INCREMENT NOT NULL,
   author_name varchar(100) NOT NULL,
   author_id text NOT NULL,
   message text NOT NULL,
   likes_count int DEFAULT NULL, 
   comments_count int DEFAULT NULL, 	
   created_time timestamp NOT NULL,
   updated_time timestamp NOT NULL,
   post_id varchar(100) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);

--Function InsertPost
delimiter //
CREATE FUNCTION InsertPost(author_name VARCHAR(100), author_id TEXT, message TEXT, likes_count INT(11), 
        comments_count INT(11), created_time timestamp, updated_time timestamp, post_id VARCHAR(100)) 
        RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT INTO posts (author_name, author_id, message, likes_count, comments_count, created_time, updated_time, post_id) VALUES (author_name, author_id, message, likes_count, comments_count, created_time, updated_time, post_id) 
        ON DUPLICATE KEY UPDATE likes_count = likes_count, comments_count = comments_count, updated_time = updated_time; 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

--Table structure for links
CREATE TABLE IF NOT EXISTS links (
  url varchar(255) NOT NULL UNIQUE,
  title text NOT NULL,
  post_id varchar(100) NOT NULL,
  id int NOT NULL AUTO_INCREMENT,
  description text NOT NULL,
  PRIMARY KEY (id)
);

--Function InsertLink
delimiter //
CREATE FUNCTION InsertLink(url varchar(255), title text, post_id varchar(100), description text) 
        RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT IGNORE INTO links (url, title, post_id, description) VALUES (url, title, post_id, description); 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

--Table structure for likes
CREATE TABLE IF NOT EXISTS likes (
  post_id varchar(100) NOT NULL,
  user_id varchar(100) NOT NULL,
  post_user varchar(255) NOT NULL UNIQUE,
  created_at timestamp NOT NULL,
  id int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (id)
);

--Function InsertLike
delimiter //
CREATE FUNCTION InsertLike(post_id varchar(100), user_id varchar(100), created_at timestamp) 
        RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT IGNORE INTO likes (post_id, user_id, post_user, created_at) VALUES (post_id, user_id, CONCAT(post_id,'_',user_id), created_at); 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

--Table structure for comments
CREATE TABLE IF NOT EXISTS comments (
  comment_id varchar(100) NOT NULL UNIQUE,
  post_id varchar(100) NOT NULL,
  user_id varchar(100) NOT NULL,
  comment_text text NOT NULL,
  comment_length int NOT NULL,
  likes_count int DEFAULT 0,
  created_time timestamp NOT NULL,
  id int AUTO_INCREMENT NOT NULL,
  PRIMARY KEY (id)
);

--Function InsertComment
delimiter //
CREATE FUNCTION InsertComment(comment_id varchar(100), post_id varchar(100), user_id varchar(100), 
            comment_text text, comment_length int, likes_count int, created_at timestamp) 
            RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT INTO comments (comment_id, post_id, user_id, comment_text, comment_length, likes_count, created_time ) 
        VALUES (comment_id, post_id, user_id, comment_text, comment_length, likes_count, created_time) 
        ON DUPLICATE KEY UPDATE likes_count = likes_count, comment_text = comment_text, comment_length = comment_length; 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

--Table structure for user
CREATE TABLE IF NOT EXISTS user (
  user_id varchar(100) NOT NULL UNIQUE,
  active boolean DEFAULT 0, 
  firstname varchar(100) NOT NULL,
  middlename varchar(100) DEFAULT NULL,
  lastname varchar(100) DEFAULT NULL,
  gender varchar(1) DEFAULT NULL,
  location varchar(255) DEFAULT NULL,
  link text DEFAULT NULL,
  username varchar(100) NOT NULL,
  id int AUTO_INCREMENT NOT NULL,
  PRIMARY KEY(id)
);

--Function InsertUser
delimiter //
CREATE FUNCTION InsertUser(user_id varchar(100), active boolean, firstname varchar(100), middlename varchar(100), lastname varchar(100), gender varchar(1), location varchar(255), link text, username varchar(255)) 
            RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT INTO user(user_id, active, firstname, middlename, lastname, gender, location, link, username) 
        VALUES (user_id, active, firstname, middlename, lastname, gender, location, link, username) 
        ON DUPLICATE KEY UPDATE active = active, firstname = firstname, middlename = middlename, lastname = lastname, gender = gender, location = location, link = link; 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

--Table structure for user_points
CREATE TABLE IF NOT EXISTS user_points (
  id int AUTO_INCREMENT NOT NULL,
  user_id varchar(100) NOT NULL UNIQUE,
  comments_o_count int NOT NULL DEFAULT 0,
  comments_u_count int NOT NULL DEFAULT 0,
  likes_o_count int NOT NULL DEFAULT 0,
  likes_u_count int NOT NULL DEFAULT 0,
  post_points int NOT NULL DEFAULT 0,
  xtra_points int NOT NULL DEFAULT 0,
  total_points int NOT NULL DEFAULT 0,
  updated_at timestamp NOT NULL,
  PRIMARY KEY(id)
);

--Function InsertUserPoints
delimiter //
CREATE FUNCTION InsertUserPoints(user_id varchar(100), comments_o_count int, comments_u_count int, likes_o_count int, likes_u_count int, post_points int, xtra_points int, updated_at timestamp) 
            RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT INTO user_points (user_id, comments_o_count, comments_u_count, likes_o_count, likes_u_count, 
            post_points, xtra_points, total_points, updated_at) 
        VALUES (user_id, comments_o_count, comments_u_count, likes_o_count, likes_u_count, 
            post_points, xtra_points, post_points+xtra_points, updated_at) 
        ON DUPLICATE KEY UPDATE comments_o_count = comments_o_count, comments_u_count = comments_u_count, 
            likes_o_count = likes_o_count, likes_u_count = likes_u_count, post_points = post_points, 
            xtra_points = xtra_points, total_points = post_points + xtra_points, updated_at = updated_at; 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

