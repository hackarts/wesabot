# Plugin to display available commands for each plugin
class HelpPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  priority 0

  def process(message)
    person = message.person
    case message.command
    when /help(?:\s(.*))?/i
      if $1
        name = $1
        plugin = plugin_helps.keys.find do |k|
          k =~ /(#{name}|#{name.gsub(/s$/i, '')})(plugin)?/i
        end
        matched_helps = { plugin => plugin_helps[plugin] } if plugin
      end
      matched_helps ||= plugin_helps

      bot.paste msg_for(matched_helps)
      return HALT
    end
  end

  # return array of available commands and descriptions
  def help
    [['help', "this message"]]
  end

protected

  def plugin_helps
    @plugin_helps ||= begin
      help = bot.plugins.map do |plugin|
        begin
          [plugin.to_s, plugin.help] if plugin.respond_to?(:help)
        rescue Exception => e
          bot.log_error(e)
        end
      end.compact
      Hash[help]
    end
  end

  def msg_for(help)
    help.keys.sort.map do |plugin|
      cmds = help[plugin].map do |command, description|
        " - #{command}\n     #{description}\n"
      end.join
      "#{plugin}:\n" + cmds
    end.join("\n")
  end

end
