require "tinder"

module Campfire
  class Bot
    attr_accessor :config, :room, :name, :campfire, :debug

    def initialize(config)
      self.config = config
      options = {:token => config.api_token, :ssl_verify => config.ssl_verify }
      self.campfire = Tinder::Campfire.new(config.subdomain, options)
      begin
        self.name = campfire.me['name']
        self.room = campfire.find_room_by_name(config.room) or
          raise ConfigurationError, "Could not find a room named '#{config.room}'"
      rescue Tinder::AuthenticationFailed => e
        raise # maybe do some friendlier error handling later
      end
      room.join
      say("hey guys")
    end

    def base_uri
      campfire.connection.uri.to_s
    end

    # convenience method so I don't have to change all the old #say method to #speak
    def say(*args)
      room.speak(*args)
    end

    # pick something at random from an array of sayings
    def say_random(sayings)
      say(sayings[rand(sayings.size)])
    end

    # return a random person out of the list of users logged in to this room
    def other_person(exclude = nil)
      # don't choose the excluded person or ourself
      options = room.users.reject{|u| u[:name] =~ /^(#{exclude}|#{self.name})/ }
      # return the other person's first name, or nil if we didn't find one
      options.any? ? options[rand(options.size)][:name].split(' ').first : nil
    end

    def logger
      config.logger
    end

    # Proxy everything to the room.
    def method_missing(m, *args)
      room.send(m, *args)
    end
  end
end
