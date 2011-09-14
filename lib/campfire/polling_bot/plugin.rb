# Campfire AbstractPollingBot Plugin base class
#
# To create a plugin, extend from this class, and just drop it into the plugins directory.
# See sample_plugin.rb for more information.
#
require 'dm-core'
require 'dm-migrations'

module Campfire
  class PollingBot
    class Plugin
      attr_accessor :config

      def initialize
        # load the config file if we have one
        name = self.to_s.gsub(/([[:upper:]]+)([[:upper:]][[:lower:]])/,'\1_\2').
            gsub(/([[:lower:]\d])([[:upper:]])/,'\1_\2').
            tr("-", "_").
            downcase
        config_dir = bot.config.config_dir || self.class.directory
        filepath = File.join(config_dir, "#{name}.yml")
        if File.exists?(filepath)
          self.config = YAML.load_file(filepath)
        else
          self.config = {}
        end
      end

      # keep track of subclasses
      def self.inherited(klass)
        # save the plugin's directory
        filepath = caller[0].split(':')[0]
        klass.directory = File.dirname(caller[0].split(':')[0])
        super if defined? super
      ensure
        ( @subclasses ||= [] ).push(klass).uniq!
      end

      def self.subclasses
        @subclasses ||= []
        @subclasses.inject( [] ) do |list, subclass|
          list.push(subclass, *subclass.subclasses)
        end
      end

      def self.directory=(dir)
        @directory = dir
      end

      def self.directory
        @directory
      end

      # bot accessor
      def self.bot
        @@bot
      end
      def self.bot=(bot)
        @@bot = bot
      end
      attr_writer :bot
      def bot
        @bot || self.class.bot
      end

      def logger
        bot.logger
      end

      HALT = 1 # returned by a command when command processing should halt (continues by default)

      def self.load_all(bot)
        self.bot = bot

        load_plugin_classes

        # set up the database now that the plugins are loaded
        setup_database(bot.config.datauri)

        plugin_classes = self.subclasses.sort {|a,b| b.priority <=> a.priority }
        # initialize plugins
        plugins = plugin_classes.map { |p_class| p_class.new }
        # remove any plugins that require a config and don't have one
        plugins.reject! {|p| p.requires_config? and p.config.empty?}
        return plugins
      end

      def self.load_plugin_classes
        # add each plugin dir to the load path
        Dir.glob(File.dirname(__FILE__) + "/plugins/*").each {|dir| $LOAD_PATH << dir }
        # load core first
        paths  = Dir.glob(File.dirname(__FILE__) + "/plugins/shared/*.rb")
        # load all models & plugins
        paths += Dir.glob(File.dirname(__FILE__) + "/plugins/*/*.rb")
        paths.each do |path|
          begin
            path.match(/(.*?)\.rb$/) && (require $1)
          rescue Exception => e
            $stderr.puts "Unable to load #{path}: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
          end
        end
      end

      # set up the plugin database
      def self.setup_database(datauri)
        DataMapper.setup(:default, datauri)
        DataMapper.auto_upgrade!
        # not related to setting up the database, but for lack of a better place....
        DataMapper::Model.raise_on_save_failure = true
      end

      # method to set or get the priority. Higher value == higher priority. Default is 0
      # command subclasses set their priority like so:
      #   class FooPlugin << Campfire::PollingBot::Plugin
      #     priority 10
      #   ...
      def self.priority(value = nil)
        if value
          @priority = value
        end
        return @priority || 0
      end

      # convenience method to get the priority of a plugin instance
      def priority
        self.class.priority
      end

      def self.requires_config(flag = true)
        @requires_config = flag
      end

      def self.requires_config?
        @requires_config
      end

      def requires_config?
        self.class.requires_config?
      end

      # called from Plugin objects to indicate what kinds of messages they accept
      # if the :addressed_to_me flag is true, it will only accept messages addressed
      # to the bot (e.g. "Wes, ____" or "______, Wes")
      # Examples:
      #   accepts :text_message, :addressed_to_me => true
      #   accepts :enter_message
      #   accepts :all
      def self.accepts(message_type, params = {})
        @accepts ||= {}
        if message_type == :all
          @accepts[:all] = params[:addressed_to_me] ? :addressed_to_me : :for_anyone
        else
          klass = Campfire.const_get(message_type.to_s.gsub(/(?:^|_)(\S)/) {$1.upcase})
          @accepts[klass] = params[:addressed_to_me] ? :addressed_to_me : :for_anyone
        end
      end

      # returns true if the plugin accepts the given message type
      def self.accepts?(message)
        if @accepts[:all]
          @accepts[:all] == :addressed_to_me ? bot.addressed_to_me?(message) : true
        elsif @accepts[message.class]
          @accepts[message.class] == :addressed_to_me ? bot.addressed_to_me?(message) : true
        end
      end

      # convenience method to call accepts on a plugin instance
      def accepts?(message)
        self.class.accepts?(message)
      end

      def to_s
        self.class.to_s
      end
    end
  end
end
