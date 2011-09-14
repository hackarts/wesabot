require 'airbrake/api'
require 'airbrake/error'

class AirbrakePlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  priority 10
  requires_config
  
  def initialize
    super
    @api = Airbrake::API.new(config['domain'], config['auth_token'])
  end

  def process(message)
    case message.command
    when /((?:un(?:-)?)?resolve) error (?:#|number)?\s*(\d+)/
      action, error_num = $1, $2
      res = @api.resolve_error(error_num, action == "resolve")
      case res.code
      when 200
        bot.say("Ok, #{action}d error ##{error_num}")
      when 404
        bot.say("Hmm. Airbrake couldn't find error ##{error_num}")
      else
        bot.say("Huh. Airbrake gave me this response:")
        bot.paste(res.to_s)
      end
      return HALT
    end
  end

  def heartbeat
    # check every <check_interval> seconds (heartbeat is called every 3 sec)
    num_heartbeats = config['check_interval'] / Campfire::PollingBot::HEARTBEAT_INTERVAL
    @heartbeat_counter ||= 0
    @heartbeat_counter += 1
    return unless (@heartbeat_counter % num_heartbeats) == 1
    handle_errors
  end

  def handle_errors
    # fetch errors we know about, announce new ones, and remove resolved ones
    unresolved_errors = @api.errors
    known_errors = Airbrake::Error.all
    new_errors = unresolved_errors - known_errors
    resolved_errors = known_errors - unresolved_errors
    resolved_errors.each {|e| e.destroy }
    new_errors.each {|e| e.save }
    announce(new_errors) if new_errors.any?
  end

  def announce(errors)
    msg = "Got #{errors.length} new error#{errors.length > 1 ? 's' : ''} from Airbrake" + 
          (errors.length > 5 ? ". Here are the first 5:" : ":")
    bot.say(msg)
    errors.first(5).each { |e| bot.say("#{e.summary} (#{@api.error_url(e)})") }
  end

    # return array of available commands and descriptions
  def help
    [["resolve <error number>", "mark an error as resolved"],
     ["unresolve <error number>", "mark an error as unresolved"]]
  end
end