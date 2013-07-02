CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(100) NOT NULL,
  lname VARCHAR(100) NOT NULL
  );

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  body TEXT,
  author_id INT(3) NOT NULL,
  FOREIGN KEY(author_id) REFERENCES users(id)
  );

CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  question_id INT(3) NOT NULL,
  follower_id INT(3) NOT NULL,
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(follower_id) REFERENCES users(id)
  );

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INT(3) NOT NULL,
  parent_id INT(3),
  body TEXT NOT NULL,
  author_id INT(3) NOT NULL,
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(parent_id) REFERENCES replies(id),
  FOREIGN KEY(author_id) REFERENCES users(id)
  );

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  user_id INT(3),
  question_id INT(3),
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
  );

INSERT INTO users (fname, lname) VALUES ('Prolific', 'User'),
('Quiet', 'User'),
('Donald', 'Duck'),
('Daffy', 'Duck');

INSERT INTO questions (title, body, author_id)
  VALUES ('Why are there so many songs about rainbows?',
                       'Whats on the other side', 1),
          ('How much would would a woodchuck chuck?', NULL, 2);

INSERT INTO question_followers (question_id, follower_id) VALUES (1, 1),(1, 2),
 (1, 3),(1, 4),(2, 2), (2, 4);

INSERT INTO replies (question_id, parent_id, body, author_id)
  VALUES (1, NULL, 'Dont know', 3), (1, 1, 'I dont know either', 4);

INSERT INTO question_likes (user_id, question_id) VALUES (1, 2),(2, 2),(2, 1);
