class User
  include DataMapper::Resource
  property :id,          Serial
  property :name,        String, :index => true
  property :campfire_id, Integer, :index => true

  has n, :messages

  def short_name
    name && name.split(' ').first
  end

  def wants_greeting?
    greeting_setting = GreetingSetting.for_user(self)

    if greeting_setting
      greeting_setting.wants_greeting
    else
      true
    end
  end

  def wants_greeting=(yesno)
    greeting_setting = GreetingSetting.for_user(self)

    if greeting_setting
      greeting_setting.update(:wants_greeting => yesno)
    else
      GreetingSetting.create(:user => self, :wants_greeting => yesno)
    end
  end
end
