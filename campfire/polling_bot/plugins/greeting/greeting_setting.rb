# used by GreetingPlugin
class GreetingSetting
  include DataMapper::Resource
  property :id,             Serial
  property :person,         String, :index => true
  property :wants_greeting, Boolean

  belongs_to :user, :required => false

  def self.for_user(user)
    result = first(:user => user) || first(:person => user.name, :user => nil)

    if result && result.user.nil?
      result.update(:user => user)
    end

    return result
  end
end
