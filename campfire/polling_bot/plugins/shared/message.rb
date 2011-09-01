# used by HistoryPlugin, among others
class Message
  include DataMapper::Resource
  property :id,           Serial
  property :room,         Integer, :required => true, :index => true
  property :message_id,   Integer, :required => true
  property :message_type, String, :length => 20, :required => true, :index => true
  property :person,       String, :index => true
  property :user_id,      Integer, :required => false, :index => true
  property :link,         Text, :lazy => false
  property :body,         Text, :lazy => false
  property :timestamp,    Integer, :required => true, :index => true

  belongs_to :user, :required => false

  def self.last_message(name, time = nil)
    first(:conditions => {
        :person => name,
        :message_type.not => 'Enter',
        :timestamp.lt => (time || Time.now)
      }, :order => [:timestamp.desc])
  end

  def self.last_left(name, time = nil)
    first(:conditions => {
        :person => name,
        :message_type => ['Leave','Kick'],
        :timestamp.lt => (time || Time.now)
      }, :order => [:timestamp.desc])
  end
  
  # guess whether the message is still on the screen by counting
  # how many messages there are between it and now
  def visible?
    self.class.count(:id.gt => id) < 20
  end
end
