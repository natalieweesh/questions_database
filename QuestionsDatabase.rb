require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super("questions.db")
    self.results_as_hash = true
    self.type_translation = true
  end

end

class User
  attr_accessor :fname, :lname
  attr_reader :id

  def initialize(options = {})
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    users
      WHERE   id = ?
      SQL
    unless hash.nil?
      user = User.new(hash)
      user.set_id(id)
      return user
    end
    nil
  end

  def self.find_by_name(fname, lname)
    hash = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)[0]
      SELECT  *
      FROM    users
      WHERE   fname = ?
      AND     lname = ?
      SQL
    unless hash.nil?
      user = User.new(hash)
      user.set_id(hash["id"])
      return user
    end
    nil
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    karma = QuestionsDatabase.instance.execute(<<-SQL, @id)[0]["AVG(count)"]
      SELECT AVG(count)
      FROM
        (SELECT   COUNT(*) count
        FROM     question_likes
        JOIN     questions
        ON       questions.id = question_likes.question_id
        WHERE    questions.author_id = ?
        GROUP BY questions.id)
      SQL
    karma
  end

  def save
    if @id == nil
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname
      INSERT INTO users (fname, lname)
      VALUES (?, ?)
      SQL
    )
    @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id
      UPDATE users
      SET fname = ?, lname = ?
      WHERE id = ?
      SQL
    )
    end
  end



end

class Question

  attr_accessor :title, :body, :author_id
  attr_reader :id

  def initialize(options = {})
    @title = options["title"]
    @body = options["body"]
    @id = options["id"]
    @author_id = options["author_id"]
  end


  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    questions
      WHERE   id = ?
      SQL
    return Question.new(hash) unless hash.nil?
    nil
  end

  def self.find_by_author_id(author_id)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT  *
      FROM    questions
      WHERE   author_id = ?
      SQL
    hash_array.map {|hash| Question.new(hash)}
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollower.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def save
    if @id == nil
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id
      INSERT INTO questions (title, body, author_id)
      VALUES (?, ?, ?)
      SQL
    )
    @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id
      UPDATE questions
      SET title = ?, body = ?, author_id = ?
      WHERE id = ?
      SQL
    )
    end
  end



end

class QuestionFollower

  attr_accessor :question_id, :follower_id
  attr_reader :id

  def initialize(options = {})
    @question_id = options["question_id"]
    @follower_id = options["follower_id"]
    @id = options["id"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    question_followers
      WHERE   id = ?
      SQL
    return QuestionFollower.new(hash) unless hash.nil?
    nil
  end

  def self.followers_for_question_id(question_id)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT  users.id, users.fname, users.lname
      FROM    question_followers
      JOIN    users
        ON      users.id = question_followers.follower_id
      WHERE   question_id = ?
      SQL
    hash_array.map {|hash| User.new(hash)}
  end

  def self.followed_questions_for_user_id(user_id)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT  questions.id, questions.title, questions.body, questions.author_id
      FROM    question_followers
      JOIN    questions
        ON    questions.id = question_followers.question_id
      WHERE   question_followers.follower_id = ?
      SQL
    hash_array.map {|hash| Question.new(hash)}
  end

  def self.most_followed_questions(n)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT   questions.id, questions.title, questions.body, questions.author_id
      FROM     questions
      JOIN     question_followers
      ON       questions.id = question_followers.question_id
      GROUP BY questions.id
      ORDER BY COUNT(*) DESC
      LIMIT ?
      SQL
    hash_array.map {|hash| Question.new(hash)}
  end

end

class Reply

  attr_accessor :question_id, :parent_id, :body, :author_id
  attr_reader :id

  def initialize(options = {})
    @question_id = options["question_id"]
    @parent_id = options["parent_id"]
    @body = options["body"]
    @author_id = options["author_id"]
    @id = options["id"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    replies
      WHERE   id = ?
      SQL
    return Reply.new(hash) unless hash.nil?
    nil
  end

  def self.find_by_question_id(question_id)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM replies
      WHERE replies.question_id = ?
      SQL
    hash_array.map {|hash| Reply.new(hash)}
  end

  def self.find_by_user_id(user_id)
    reply_ids = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT  *
      FROM    replies
      WHERE   author_id = ?
      SQL
    reply_ids.map {|hash| Reply.new(hash)}
  end

  def author
    User.find_by_id(@author_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    if @parent_id
      Reply.find_by_id(@parent_id)
    else
      nil
    end
  end

  def child_replies
    reply_ids = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT  *
      FROM    replies
      WHERE   parent_id = ?
      SQL
    reply_ids.map {|hash| Reply.new(hash)}
  end

  def save
    if @id == nil
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @body, @author_id
      INSERT INTO replies (question_id, parent_id, body, author_id)
      VALUES (?, ?, ?, ?)
      SQL
    )
    @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @body, @author_id, @id
      UPDATE replies
      SET question_id = ?, parent_id = ?, body = ?, author_id = ?
      WHERE id = ?
      SQL
    )
    end
  end

end

class QuestionLike
  attr_accessor :user_id, :question_id
  attr_reader :id

  def initialize(options = {})
    @user_id = options["user_id"]
    @question_id = options["question_id"]
    @id = options["id"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    question_likes
      WHERE   id = ?
      SQL
    return QuestionLike.new(hash) unless hash.nil?
    nil
  end

  def self.likers_for_question_id(question_id)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT   users.id, users.fname, users.lname
      FROM     question_likes
      JOIN     users
      ON       users.id = question_likes.user_id
      WHERE    question_likes.question_id = ?
      SQL
    hash_array.map {|hash| User.new(hash)}
  end

  def self.num_likes_for_question_id(question_id)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, question_id)[0]["COUNT(*)"]
      SELECT   COUNT(*)
      FROM     question_likes
      WHERE    question_likes.question_id = ?
      SQL
  end

  def self.most_liked_questions(n)
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT   questions.id, questions.title, questions.body, questions.author_id
      FROM     questions
      JOIN     question_likes
      ON       questions.id = question_likes.question_id
      GROUP BY questions.id
      ORDER BY COUNT(*) DESC
      LIMIT ?
      SQL
    hash_array.map {|hash| Question.new(hash)}
  end

end


class Tag
  attr_reader :id

  attr_accessor :tag

  def initialize(options={})
    @tag = options["tag"]
    @id = options["id"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    tags
      WHERE   id = ?
      SQL
    return Tag.new(hash) unless hash.nil?
    nil
  end

  def self.most_popular
    hash_array = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT   inner_thing.id, inner_thing.title, inner_thing.body, inner_thing.author_id
      FROM     (
        SELECT questions.id, questions.title, questions.body, questions.author_id, COUNT(*) count
        FROM   questions
        JOIN   question_likes
        ON     question_likes.question_id = questions.id
        GROUP BY question_likes.question_id
        ) inner_thing
      JOIN question_tags
      ON inner_thing.id = question_tags.question_id
      GROUP BY question_tags.tag_id
      HAVING inner_thing.count = MAX(inner_thing.count)
      SQL
      hash_array.map { |hash| Question.new(hash)}
  end

end

class QuestionTag
  attr_reader :id

  attr_accessor :question_id, :tag_id

  def initialize(options={})
    @question_id = options["question_id"]
    @tag_id = options["tag_id"]
    @id = options["id"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    question_tags
      WHERE   id = ?
      SQL
    return QuestionTag.new(hash) unless hash.nil?
    nil
  end


end