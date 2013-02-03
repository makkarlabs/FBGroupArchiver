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

--Function UpdateLikePoints
delimiter //
CREATE FUNCTION UpdateLikePoints(post_id varchar(100), user_id varchar(100), affected_rows int) RETURNS INT
    BEGIN
        DECLARE owner_id int;
        DECLARE owner_ins int;
        DECLARE user_ins int;
        IF affected_rows = 1 
        THEN
            SELECT author_id INTO owner_id from posts where post_id = post_id;
            SELECT InsertUserPoints(owner_id) INTO owner_ins;
            SELECT InsertUserPoints(user_id) INTO user_ins;
            UPDATE user_points set like_o_count = like_o_count + 1 where user_id = owner_id;
            UPDATE user_points set like_u_count = like_u_count + 1 where user_id = user_id;
        END IF;
        return 0;
    END//
delimiter ;

--Function InsertLike
delimiter //
CREATE FUNCTION InsertLike(post_id varchar(100), user_id varchar(100), created_at timestamp) 
        RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        DECLARE update_like INT;
        INSERT IGNORE INTO likes (post_id, user_id, post_user, created_at) VALUES (post_id, user_id, CONCAT(post_id,'_',user_id), created_at); 
        SELECT ROW_COUNT() INTO affected_rows;
        SELECT UpdateLikePoints(post_id, user_id, affected_rows) into update_like;
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

--Function UpdateCommentPoints
delimiter //
CREATE FUNCTION UpdateCommentPoints(post_id varchar(100), user_id varchar(100), affected_rows int, comment_length int, comment_words int)
    RETURNS INT
    BEGIN
        DECLARE owner_id INT;
        DECLARE owner_ins int;
        DECLARE user_ins int;
        
        SELECT author_id from posts where post_id = post_id into owner_id;
        SELECT InsertUserPoints(owner_id) into owner_ins;
        SELECT InsertUserPoints(user_id) into user_ins;

        IF affected_rows = 1 THEN
            UPDATE user_points set comment_o_count = comment_o_count + 1 where user_id = owner_id;
            UPDATE user_points set comment_u_count = comment_u_count + 1 where user_id = user_id;
            IF (comment_length > 50 && comment_length < 100) THEN
                UPDATE user_points set xtra_points = xtra_points + 5 where user_id = owner_id;
                UPDATE user_points set xtra_points = xtra_points + 25 where user_id = user_id;
            ELSEIF comment_length >= 100 THEN
                UPDATE user_points set xtra_points = xtra_points + 10 where user_id = owner_id;
                UPDATE user_points set xtra_points = xtra_points + 50 where user_id = user_id;
            END IF;
        
        ELSEIF affected_rows = 2 THEN
            IF comment_words != comment_length THEN
                IF (comment_length > 50 && comment_length < 100) THEN
                    UPDATE user_points set xtra_points = xtra_points - 5 where user_id = owner_id;
                    UPDATE user_points set xtra_points = xtra_points - 25 where user_id = user_id;
                ELSEIF comment_length >= 100 THEN
                    UPDATE user_points set xtra_points = xtra_points - 10 where user_id = owner_id;
                    UPDATE user_points set xtra_points = xtra_points - 50 where user_id = user_id;
                END IF;
                IF (comment_words > 50 && comment_words < 100) THEN
                    UPDATE user_points set xtra_points = xtra_points + 5 where user_id = owner_id;
                    UPDATE user_points set xtra_points = xtra_points + 25 where user_id = user_id;
                ELSEIF comment_words >= 100 THEN
                    UPDATE user_points set xtra_points = xtra_points + 10 where user_id = owner_id;
                    UPDATE user_points set xtra_points = xtra_points + 50 where user_id = user_id;
                END IF;
            END IF;
        END IF;
        return 0;
    END//
delimiter ;

--Function InsertComment
delimiter //
CREATE FUNCTION InsertComment(comment_id varchar(100), post_id varchar(100), user_id varchar(100), 
            comment_text text, comment_length int, likes_count int, created_time timestamp) 
            RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT;
        DECLARE comment_words INT;
        DECLARE update_comment INT;
        SELECT comment_length from comments where comment_id = comment_id INTO comment_words;

        INSERT INTO comments (comment_id, post_id, user_id, comment_text, comment_length, likes_count, created_time ) 
        VALUES (comment_id, post_id, user_id, comment_text, comment_length, likes_count, created_time) 
        ON DUPLICATE KEY UPDATE likes_count = likes_count, comment_text = comment_text, comment_length = comment_length; 
        SELECT ROW_COUNT() INTO affected_rows;
        SELECT UpdateCommentPoints(post_id, user_id, affected_rows, comment_length, comment_words) INTO update_comment; 
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
CREATE FUNCTION InsertUserPoints(user_id varchar(100)) 
            RETURNS INT 
    BEGIN 
        DECLARE affected_rows INT; 
        INSERT IGNORE INTO user_points (user_id, updated_at) 
        VALUES (user_id, now()); 
        SELECT ROW_COUNT() INTO affected_rows; 
        RETURN affected_rows; 
    END//
delimiter ;

--Update trigger for User Points

delimiter //
CREATE TRIGGER user_point_update after UPDATE ON user_points
    FOR EACH ROW 
    BEGIN
        UPDATE user_points SET post_points = (NEW.comments_o_count * 5) + (NEW.comments_u_count * 5) 
            + (NEW.likes_o_count * 2) + (NEW.likes_u_count * 1) 
            WHERE user_id = NEW.user_id;
        UPDATE user_points SET total_points = NEW.post_points + NEW.xtra_points WHERE user_id = NEW.user_id;
        UPDATE user_points SET updated_at = now() WHERE user_id = NEW.user_id;
    END //
delimiter ;

