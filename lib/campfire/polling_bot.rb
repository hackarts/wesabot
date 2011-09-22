# PollingBot - a bot that polls the room for messages
require 'campfire/bot'
require 'campfire/message'

require 'firering'

module Campfire
  class PollingBot < Bot
    require 'campfire/polling_bot/plugin'
    attr_accessor :plugins
    HEARTBEAT_INTERVAL = 3 # seconds

    def initialize(config)
      # load plugin queue, sorting by priority
      super
      self.plugins = Plugin.load_all(self)
    end

    # main event loop
    def run
      # set up a heartbeat thread for plugins that want them
      Thread.new do
        loop do
          plugins.each {|p| p.heartbeat if p.respond_to?(:heartbeat)}
          sleep HEARTBEAT_INTERVAL
        end
      end

      host = "https://#{config.subdomain}.campfirenow.com"
      conn = Firering::Connection.new(host) do |c|
        c.token = config.api_token
        c.logger = logger
        c.retry_delay = 2
      end

      EM.run do
        conn.room(room.id) do |room|
          room.stream do |data|

            begin
              if data.from_user?
                user_message_for(data)
              else
                message_for(data)
              end
            rescue => e
              log_error(e)
            end

          end
        end

        trap("INT") { EM.stop; raise SystemExit }
      end

    rescue Exception => e # leave the room if we crash
      if e.kind_of?(SystemExit)
        room.leave
        exit 0
      else
        log_error(e)
        room.leave
        exit 1
      end
    end

    def message_from(data)
      Campfire.const_get(data.type).new(data)
    end

    def message_for(data)
      process message_from(data)
    end

    def user_message_for(data)
      data.user do |user|
        raise RuntimeError, "didn't get a user" unless user.id

        dbuser = User.first(:campfire_id => user.id)

        if dbuser.nil?
          dbuser = User.create(
            :campfire_id => user.id,
            :name => user.name
          )
        else
          dbuser.update(:name => user.name)
        end

        message = message_from(data)
        message.user = dbuser
        process message
      end
    rescue RuntimeError
      # if we didn't get a user, Campfire probably threw us a 500,
      # so we should just try to get the user info again.
      sleep 5
      retry
    end

    def process(message)
      logger.debug "processing #{message} (#{message.person} - #{message.body})"

      # ignore messages from ourself
      return if [message.person, message.person_full_name].include? self.name

      plugins.each do |plugin|
        begin
          if plugin.accepts?(message)
            logger.debug "sending to plugin #{plugin} (priority #{plugin.priority})"
            status = plugin.process(message)
            if status == Plugin::HALT
              logger.debug "plugin chain halted"
              break
            end
          end
        rescue Exception => e
          say("Oops, #{plugin.class} threw an exception. Enable debugging to see it.") unless debug
          log_error(e)
          break
        end
      end

      logger.debug "done processing #{message}"
    end

    # determine if a message is addressed to the bot. if so, store the command in the message
    def addressed_to_me?(message)
      m = message.body.match(/^#{name}(?:[,:]\s*|\s+)(.*)/i)
      m ||= message.body.match(/^\s*(.*?)(?:,\s+)?\b#{name}[.!?\s]*$/i)
      message.command = m[1] if m
    end

    def log_error(e)
      msg = "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      logger.error(msg)
      paste(msg) if debug
    end

  end
end
