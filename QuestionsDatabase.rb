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
    @id = options["id"]
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    users
      WHERE   id = ?
      SQL
    return User.new(hash) unless hash.nil?
    nil
  end

  def self.find_by_name(fname, lname)
    hash = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)[0]
      SELECT  *
      FROM    users
      WHERE   fname = ?
      AND     lname = ?
      SQL
    return User.new(hash) unless hash.nil?
    nil
  end

  # def authored_questions
  #   question_ids = QuestionsDatabase.instance.execute(<<-SQL, @id)
  #     SELECT  id
  #     FROM    questions
  #     WHERE   author_id = ?
  #     SQL
  #   question_ids.map {|hash| Question.find_by_id(hash["id"])}
  # end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
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

end