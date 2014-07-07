require "json"
require "digest/sha1"

class Poll
  ID_LEN = 3
  ID_REGEXP = "(\\w{#{ID_LEN}})"
  def initialize(topic, id=nil, options=nil, votes=nil)
    @topic = topic
    @id = id.nil? ? Digest::SHA1.hexdigest(topic).slice(0, ID_LEN) : id
    @options = options.nil? ? [] : options
    @votes = votes.nil? ? {} : votes
  end

  def topic
    return @topic
  end

  def id
    return @id
  end

  def options
    return @options
  end

  def votes
    return @votes
  end

  def set_option(opt)
    @options.push(opt)
  end

  def valid_vote?(optNum)
    optNum-1 < @options.length
  end

  def vote(user, optNum)
    @votes[user.id] = optNum
  end

  def to_json(*args)
  {
    "id" => @id, "topic" => @topic, "options" => @options, "votes" => @votes
  }.to_json(*args)
  end

  def self.json_create(o)
    new(o["topic"], o["id"], o["options"], o["votes"])
  end
end