# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "campfire/version"

Gem::Specification.new do |s|
  s.name        = "wesabot"
  s.version     = Campfire::VERSION
  s.authors     = ["Brad Greenlee", "André Arko", "Brian Donovan"]
  s.email       = ["brad@footle.org", "andre@arko.net", "me@brian-donovan.com"]
  s.homepage    = "https://github.com/hackarts/wesabot"
  s.summary     = %q{Wesabe's Campfire bot framework}
  s.description = %q{Wesabot is a Campfire bot framework we've been using and 
    developing at Wesabe since not long after our inception. It started as a 
    way to avoid parking tickets near our office ("Wes, remind me in 2 hours 
    to move my car"), and has evolved into an essential work aid. When you 
    enter the room, Wes greets you with a link to the point in the transcript 
    where you last left. You can also ask him to bookmark points in the 
    transcript, send an sms message (well, an email) to someone, or even post 
    a tweet, among other things. His functionality is easily extendable via 
    plugins.}

  s.rubyforge_project = "wesabot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  ### core dependencies
  s.add_dependency "tinder", "~> 1.7.0"
  s.add_dependency "data_mapper", "~> 1.1"
  s.add_dependency "dm-sqlite-adapter", "~> 1.1"
  s.add_dependency "daemons"
  s.add_dependency "i18n"
  s.add_dependency "firering", "~> 1.2.0"

  ### plugin dependencies

  # airbrake
  s.add_dependency "nokogiri"
  s.add_dependency "rest-client"

  # image_search
  s.add_dependency "httparty" # also used by twitter_search
  s.add_dependency "google-search"

  # remind_me
  s.add_dependency "chronic"

  ### development dependencies  
  s.add_development_dependency "rspec", "~> 2.6.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "ruby-debug"

end
