# Plugin to greet people when they enter, provide a catch-up url, and notify them of any "future" messages
# requires the HistoryPlugin
class GreetingPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  accepts :enter_message

  def process(message)
    user = message.user
    wants_greeting = wants_greeting?(user)
    if message.kind_of?(Campfire::EnterMessage)
      link = catch_up_link(message.person_full_name)
      futures = future_messages(message.person_full_name, message.person)
      if wants_greeting && link
        bot.say("Hey #{message.person.downcase}. Catch up: #{link}")
      end
      futures.each{|m| bot.say(m) }
    elsif message.kind_of?(Campfire::TextMessage)
      case message.command
      when /(disable|turn off) greetings/i
        wants_greeting(user, false)
        bot.say("OK, I've disabled greetings for you, #{message.person}")
        return HALT
      when /(enable|turn on) greetings/i
        wants_greeting(user, true)
        bot.say("OK, I've enabled greetings for you, #{message.person}")
        return HALT
      when /toggle greetings/i
        old_setting = wants_greeting?(user)
        wants_greeting(user, !old_setting)
        bot.say("OK, I've #{old_setting ? 'disabled' : 'enabled'} greetings for you, #{message.person}")
        return HALT
      when /catch me up|ketchup/i
        if link = catch_up_link(message.person_full_name, true)
          bot.say("Here you go, #{message.person}: #{link}")
        else
          bot.say("Hmm...couldn't find when you last logged out, #{message.person}")
        end
        return HALT
      end
    end
  end
  # return array of available commands and descriptions
  def help
    [['(disable|turn off) greetings', "don't say hi when you log in (you grump)"],
     ['(enable|turn on) greetings', "say hi when you log in"],
     ['toggle greetings', "disable greetings if enabled, enable if disabled. You know--toggle."],
     ['catch me up|ketchup', "gives you a link to the point in the transcript where you last logged out"]
    ]
  end

  private

  # return the last message we saw from the user
  def last_message(person_full_name)
    # look for a leave message
    last_left = Message.last_left(person_full_name)
    # look for any message more than a couple minutes ago (this allows us
    # to say hi in CF and then ask for a catch-up link without getting a link
    # to the message we just sent)
    last_message = Message.last_message(person_full_name, Time.now - 120)

    if last_left && last_left.message_type == 'Kick'
      # if person timed out, look for their last entry before the timeout
      last_seen = last_message
    else
      # if the person said things after their last leave message, they are
      # probably still in the room, so we use their last message instead
      last_seen = [last_left, last_message].compact.sort_by{|m| m.timestamp }.last
    end

    return last_seen
  end

  # get link to when the user last left the room so they can catch up
  # only return a link if the user has been gone long enough, unless forced
  def catch_up_link(person_full_name, force=false)
    message = last_message(person_full_name)
    # only give a link if the last message is likely no longer on the first page
    if message && (force || !message.visible?)
      return message_link(message.message_id)
    else
      return nil
    end
  end

  # Tell the person who's just entered about what people were asking them to
  # read about while they were gone.
  def future_messages(person_full_name, person)
    future_messages = []
    verbs = ["invoked", "called to", "cried out for", "made a sacrifice to", "let slip",
             "doorbell ditched", "whispered sweetly to", "walked over broken glass to get to",
             "prayed to the god of", "ran headlong at", "checked in a timebomb for",
             "interpolated some strings TWO TIMES for", "wished upon a", "was like, oh my god",
             "went all", "tested the concept of"]

    # future Brian/future Brian Donovan
    names = [person_full_name, person]

    # future BD
    name_words = person_full_name.split(/\s+/)
    names << (name_words.first[0,1]+name_words.last[0,1]) if name_words.size > 1

    future_person = Regexp.new("(?:future |@)(#{names.join('|')})\\b", Regexp::IGNORECASE)
    future_everybody = Regexp.new("(?:future |@)everybody", Regexp::IGNORECASE)

    if message = last_message(person_full_name)
      candidates = Message.all(
        :message_id.gt => message.message_id,
        :person.not => ['Fogbugz','Subversion','Capistrano',bot.name],
        :message_type => 'Text')
      candidates.each do |row|
        if row.body.match(future_person)
          verbed = verbs[rand(verbs.size)]
          future_messages << "#{row.person} #{verbed} future #{person} at: #{message_link(row.message_id)}"
        elsif row.body.match(future_everybody)
          verbed = verbs[rand(verbs.size)]
          future_messages << "#{row.person} #{verbed} future everybody: \"#{row.body}\""
        end
      end
    end
    return future_messages
  end

  def wants_greeting?(user)
    @wants_greeting_cache ||= User.all.inject({}) do |memo, u|
      memo.merge(u => u.wants_greeting?)
    end

    user.wants_greeting = true if @wants_greeting_cache[user].nil?

    return @wants_greeting_cache[user]
  end

  def wants_greeting(user, wants_greeting)
    user.wants_greeting = wants_greeting
    @wants_greeting_cache[user] = wants_greeting
  end

  def message_link(id)
    "#{bot.base_uri}/room/#{bot.room.id}/transcript/message/#{id}#message_#{id}"
  end

end

