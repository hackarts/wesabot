# Toggle debug mode
class DebugPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  priority 100
  
  def process(message)
    case message.command
    when /(enable|disable) debug/i
      if $1 == 'enable'
        bot.debug = true
      else
        bot.debug = false
      end
      bot.say("ok, debugging is #{bot.debug ? 'enabled' : 'disabled'}")
      return HALT
    end
  end

  # return array of available commands and descriptions
  def help
    [['<enable|disable> debugging', "enable or disable debug mode"]]
  end
end