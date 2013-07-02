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

  def initialize(id, fname, lname)
    @fname = fname
    @lname = lname
    @id = id
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    users
      WHERE   id = ?
      SQL
    return User.new(hash["id"], hash["fname"], hash["lname"]) unless hash.nil?
    nil
  end

  def self.find_by_name(fname, lname)
    hash = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)[0]
      SELECT  *
      FROM    users
      WHERE   fname = ?
      AND     lname = ?
      SQL
    return User.new(hash["id"], hash["fname"], hash["lname"]) unless hash.nil?
    nil
  end

  def authored_questions
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT  *
      FROM    questions
      WHERE   author_id = ?
      SQL
    hash_array.map {|hash| Question.new(hash["id"], hash["title"], hash["body"], hash["author_id"])}
  end

  def authored_replies
    hash_array = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT  *
      FROM    replies
      WHERE   author_id = ?
      SQL
    hash_array.map {|hash| Reply.new(hash["id"], hash["question_id"], hash["parent_id"], hash["body"], hash["author_id"])}
  end



end

class Question

  attr_accessor :title, :body, :author_id
  attr_reader :id

  def initialize(id, title, body, author_id)
    @title = title
    @body = body
    @id = id
    @author_id = author_id
  end


  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    questions
      WHERE   id = ?
      SQL
    return Question.new(hash["id"], hash["title"], hash["body"], hash["author_id"]) unless hash.nil?
    nil
  end

end

class QuestionFollower

  attr_accessor :question_id, :follower_id
  attr_reader :id

  def initialize(id, question_id, follower_id)
    @question_id = question_id
    @follower_id = follower_id
    @id = id
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    question_followers
      WHERE   id = ?
      SQL
    return QuestionFollower.new(hash["id"], hash["question_id"], hash["follower_id"]) unless hash.nil?
    nil
  end

end

class Reply

  attr_accessor :question_id, :parent_id, :body, :author_id
  attr_reader :id

  def initialize(id, question_id, parent_id, body, author_id)
    @question_id = question_id
    @parent_id = parent_id
    @body = body
    @author_id = author_id
    @id = id
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    replies
      WHERE   id = ?
      SQL
    return Reply.new(hash["id"], hash["question_id"], hash["parent_id"], hash["body"], hash["author_id"]) unless hash.nil?
    nil
  end

end

class QuestionLike
  attr_accessor :user_id, :question_id
  attr_reader :id

  def initialize(id, user_id, question_id)
    @user_id = user_id
    @question_id = question_id
    @id = id
  end

  def self.find_by_id(id)
    hash = QuestionsDatabase.instance.execute(<<-SQL, id)[0]
      SELECT  *
      FROM    question_likes
      WHERE   id = ?
      SQL
    return QuestionLike.new(hash["id"], hash["user_id"], hash["question_id"]) unless hash.nil?
    nil
  end

end