require 'singleton'
require 'sqlite3'

 # def save
#    unless @id.nil?
#      self.update
#      return
#    end
#
#    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
#      INSERT INTO
#        users (fname,lname)
#      VALUES
#        (?, ?)
#    SQL
#
#    @id = QuestionsDatabase.instance.last_insert_row_id
#  end
#
#  def update
#    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
#      UPDATE users
#      SET   fname=?, lname=?
#      WHERE id=?
#    SQL
#  end


module Dave #Don't do this dave, please!
  def save
    ivars = self.instance_variables

    middle_str = ''
    ivars.each { |ivar| middle_str << "#{ivar[1..-1]},"}
    middle_str = middle_str[0..-2]

    bottom_str = ''
    ivars.each { |ivar| bottom_str << "?,"}
    bottom_str = bottom_str[0..-2]

    table =

    QuestionsDatabase.instance.execute(<<-SQL, *ivars[1..-1])
      INSERT INTO
        users (#{middle_str})
      VALUES
        (#{bottom_str})
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  #note: we could use self.to_s.downcase + 's' to get User to users
  #because we need the table name on line 45\

  #active support can turn camel into snake
  #also can turn Reply into replies

  def update

  end

end

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  attr_accessor :id, :fname, :lname

  include Dave

  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM users')
    results.map { |result| User.new(result) }
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT * FROM users WHERE id = ?
    SQL
    User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT * FROM users WHERE fname = ? AND lname = ?
    SQL
    User.new(user.first)
  end

  def authored_questions
    questions = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT * FROM questions WHERE userid = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  # Version 1
  # def authored_replies
  #   replies = QuestionsDatabase.instance.execute(<<-SQL, self.id)
  #   SELECT * FROM replies WHERE userid = ?
  #   SQL
  #   replies.map { |reply| Reply.new(reply) }
  # end

  def authored_replies
    Reply::find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollower::followed_questions_for_user_id(self.id)
  end

  def initialize(options = {})
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def liked_questions
    QuestionLike::liked_questions_for_user_id(user.id)
  end

  def average_karma
    karma = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT AVG(question_like_count.like_count)
      FROM
        (SELECT questions.id, COUNT(questions_like.id) AS like_count
        FROM questions
        LEFT OUTER JOIN
        questions_like  ON ( questions.id = questions_like.question_id )
        WHERE questions.user_id = ?
        GROUP BY questions.id) AS question_like_count
      SQL
    karma.first["AVG(question_like_count.like_count)"]
  end



  # def save
 #    unless @id.nil?
 #      self.update
 #      return
 #    end
 #
 #    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
 #      INSERT INTO
 #        users (fname,lname)
 #      VALUES
 #        (?, ?)
 #    SQL
 #
 #    @id = QuestionsDatabase.instance.last_insert_row_id
 #  end
 #
 #  def update
 #    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
 #      UPDATE users
 #      SET   fname=?, lname=?
 #      WHERE id=?
 #    SQL
 #  end

end

# SELECT AVG(COUNT(questions_like.id))
# FROM questions
# LEFT OUTER JOIN
# questions_like  ON ( question.id = questions_like.question_id )
#
# WHERE questions.user_id = ?
# GROUP BY question.id

class Question
  attr_accessor :id, :title, :body, :user_id

  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM questions')
    results.map { |result| Question.new(result) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT * FROM questions WHERE id = ?
    SQL
    Question.new(question.first)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT * FROM questions WHERE userid = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def self.most_followed(n)
    QuestionFollower::most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike::most_liked_questions(n)
  end

  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
    SELECT * FROM users WHERE userid = ?
    SQL
    User.new(author.first)
  end

  # Version 1
  # def replies
  #   replies = QuestionsDatabase.instance.execute(<<-SQL, self.id)
  #   SELECT * FROM replies WHERE question_id = ?
  #   SQL
  #   replies.map { |reply| Reply.new(reply) }
  # end

  def replies
    Reply::find_by_question_id(self.id)
  end

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def followers
    QuestionFollowers::followers_for_question_id(self.id)
  end

  def likers
    QuestionLike::likers_for_question_id(self.id)
  end

  def num_likes
    num_likes_for_question_id(self.id)
  end

  def save
    unless @id.nil?
      self.update
      return
    end

    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
      INSERT INTO
        questions (title, body, user_id)
      VALUES
        (?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
      UPDATE questions
      SET   title=?, body=?, user_id=?
      WHERE id=?
    SQL
  end

end

class QuestionFollower
  attr_accessor :id, :question_id, :user_id

  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM question_followers')
    results.map { |result| QuestionFollower.new(result) }
  end

  def self.find_by_id(id)
    question_follower = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT * FROM question_followers WHERE id = ?
    SQL
    QuestionFollower.new(question_follower.first)
  end

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT users.id, users.fname, users.lname
    FROM users
    JOIN question_followers ON (users.id=question_followers.user_id)
    WHERE question_followers.question_id = ?
    SQL
    followers.map { |follower| User.new(follower) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT questions.*
    FROM question_followers
    JOIN questions ON (question_followers.question_id=questions.id)
    WHERE question_followers.user_id = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    # If using inner join, questions without follower will be omitted
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT questions.*
    FROM questions
    LEFT OUTER JOIN
    (SELECT question_id, COUNT(user_id) AS follower_count
    FROM question_followers
    GROUP BY question_id) AS question_follow_count
      ON questions.id = question_follow_count.question_id
    ORDER BY question_follow_count.follower_count DESC
    LIMIT  ?
    SQL
    questions.map { |question| Question.new(question) }
  end
end

#Subquery that returns question id in order of most followed
# (SELECT question_id
# FROM question_followers
# GROUP BY question_id
# ORDER BY COUNT(user_id) DESC)

class Reply
  attr_accessor :id, :question_id, :reply_id, :user_id, :body

  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM replies')
    results.map { |result| Reply.new(result) }
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT * FROM replies WHERE id = ?
    SQL
    Reply.new(reply.first)
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT * FROM replies WHERE question_id = ?
    SQL
    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT * FROM replies WHERE user_id = ?
    SQL
    replies.map { |reply| Reply.new(reply) }
  end

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @reply_id = options['reply_id']
    @user_id = options['user_id']
    @body = options['body']
  end

  def author
    User::find_by_id(self.user_id)
  end

  def question
    Question::find_by_id(self.question_id)
  end

  def parent_reply
    Reply::find_by_id(self.reply_id) unless self.reply_id.nil?
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT * FROM replies WHERE reply_id = ?
    SQL
    children.map { |reply| Reply.new(reply) }
  end

  def save
    unless @id.nil?
      self.update
      return
    end

    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @reply_id, @user_id, @body)
      INSERT INTO
        replies (question_id, reply_id, user_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @reply_id, @user_id, @body, @id)
      UPDATE questions
      SET   question_id=?, reply_id=?, user_id=?, body=?
      WHERE id=?
    SQL
  end


end

class QuestionLike
  attr_accessor :id, :user_id, :question_id

  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM questions_like')
    results.map { |result| QuestionLike.new(result) }
  end

  def self.find_by_id(id)
    question_like = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT * FROM questions_like WHERE id = ?
    SQL
    QuestionLike.new(question_like.first)
  end

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT users.*
    FROM questions_like
    JOIN users ON questions_like.user_id=users.id
    WHERE question_id = ?
    SQL
    likers.map { |liker| User.new(liker) }
  end

  def self.num_likes_for_question_id(question_id)
    likers_count = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT COUNT(users.id)
    FROM questions_like
    JOIN users ON questions_like.user_id=users.id
    WHERE question_id = ?
    SQL
    likers_count.first["COUNT(users.id)"]
  end

  def self.liked_questions_for_user_id(user_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT questions.*
    FROM questions_like
    JOIN questions ON questions_like.question_id=questions.id
    WHERE questions_like.user_id = ?
    SQL
    likers.map { |liker| User.new(liker) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT questions.*
    FROM questions
    LEFT OUTER JOIN
    (SELECT question_id, COUNT(user_id) AS liker_count
    FROM questions_like
    GROUP BY question_id) AS question_liker_count
      ON questions.id = question_liker_count.question_id
    ORDER BY question_liker_count.liker_count DESC
    LIMIT  ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end


if __FILE__ == $PROGRAM_NAME
  system("rm questions.db")
  system("cat import_db.sql | sqlite3 questions.db")


  ##### testing parent reply #####
  #orphan = Reply::find_by_id(1)
  #p orphan.parent_reply

  # Testing find by alls and find by ids

  # barack = User::find_by_id(1)
  # p barack
  # all_users = User::all
  # p all_users
  #
  # puts "Questions"
  # p Question::find_by_id(1)
  # p Question::all
  #
  # puts "Reply"
  # p Reply::find_by_id(1)
  # p Reply::all
  #
  # puts "Question Followers"
  # p QuestionFollower::find_by_id(1)
  # p QuestionFollower::all
  #
  # puts "Questions Like"
  # p QuestionLike::find_by_id(1)
  # p QuestionLike::all

  ##### Medium first bullet #####

  #p QuestionFollower::followers_for_question_id(1)

  ##### Medium second bullet #####

  #p QuestionFollower::followed_questions_for_user_id(3)

  ##### Hard First Bullet #####
  #p QuestionFollower::most_followed_questions(2)

  ##### Hard 3rd Bullet #####
  #p QuestionLike::likers_for_question_id(1)
  #p QuestionLike::likers_for_question_id(2)

  ##### Hard 4th Bullet #####

  #p QuestionLike::num_likes_for_question_id(1)
  #p QuestionLike::num_likes_for_question_id(2)

  ##### Hard 5th Bullet #####

  #p QuestionLike::liked_questions_for_user_id(1)

  #### Hard 6th Bullet ####
  #p QuestionLike::most_liked_questions(2)

  #### Hard 7th Bullet ####
  # barack = User.find_by_id(1)
  # p barack.average_karma

  jessie_ventura = User.new({'fname'=>'jessie', 'lname'=>'s girl'})
  jessie_ventura.save

  p User::all

  jessie_ventura.lname = "Ventura"
  jessie_ventura.save

  p User::all
end






