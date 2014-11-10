CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  user_id INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body VARCHAR(255) NOT NULL,
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(reply_id) REFERENCES replies(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE questions_like (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

INSERT INTO
  users(fname, lname)
VALUES
  ('Barack','Obama'), ('Hillary', 'Clinton'),
  ('John', 'Mccain'), ('George', 'Washington');

INSERT INTO
  questions(title, body, user_id)
VALUES
  ('Why me?',
  'I gave them healthcare!',
  (SELECT id FROM users WHERE fname = 'Barack' AND lname = 'Obama')),

  ('Why not me?',
  'Im nice!',
  (SELECT id FROM users WHERE fname = 'Hillary' AND lname = 'Clinton'));

INSERT INTO
  question_followers(question_id, user_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'Why me?'),
  (SELECT id FROM users WHERE fname = 'John' AND lname = 'Mccain')),

  ((SELECT id FROM questions WHERE title = 'Why me?'),
  (SELECT id FROM users WHERE fname = 'George' AND lname = 'Washington'));

INSERT INTO
  replies(question_id, reply_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'Why me?'),
  NULL,
  (SELECT id FROM users WHERE fname = 'John' AND lname = 'Mccain'),
  'Because you won'),

  ((SELECT id FROM questions WHERE title = 'Why me?'),
  (SELECT id FROM replies WHERE body = 'Because you won'),
  (SELECT id FROM users WHERE fname = 'George' AND lname = 'Washington'),
  'Youll never be a president');

INSERT INTO
  questions_like(user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Barack' AND lname = 'Obama'),
  (SELECT id FROM questions WHERE title = 'Why me?')),
  ((SELECT id FROM users WHERE fname = 'John' AND lname = 'Mccain'),
  (SELECT id FROM questions WHERE title = 'Why me?')),
  ((SELECT id FROM users WHERE fname = 'Barack' AND lname = 'Obama'),
  (SELECT id FROM questions WHERE title = 'Why not me?'));
