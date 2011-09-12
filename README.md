# Wesabot

Wesabot, the Campfire bot framework.

## Description

Wesabot is a Campfire bot framework we've been using and developing at Wesabe 
since not long after our inception. It started as a way to avoid parking tickets
near our office ("Wes, remind me in 2 hours to move my car"), and has evolved 
into an essential work aid. When you enter the room, Wes greets you with a link 
to the point in the transcript where you last left. You can also ask him to 
bookmark points in the transcript, send an sms message (well, an email) to 
someone, or even post a tweet, among other things. His functionality is easily 
extendable via plugins.

To give Wes new powers, simply drop a plugin file in the plugins directory and 
restart Wes (or, via the ReloadPlugin, he can be told to reload himself). See 
`campfire/polling_bot/sample_plugin.rb` for more information, or just browse 
the included plugins. Some of the plugins are somewhat Wesabe-specific (like 
DeployPlugin, which lets us see what commits are on deck to be deployed), but 
can be adapted or ignored as you see fit.

If any of your plugins need to use a database, just drop a Datamapper model in 
the plugins/models directory and it will be automatically loaded.

## Installation

### Prerequisites

Wesabot can be installed as a gem, but [Nokogiri](http://nokogiri.org/) is
required, and it has rather complicated prerequisites that vary by platform, so
rather than reproducing that information here, please see
<http://nokogiri.org/tutorials/installing_nokogiri.html>.

You'll also need to install [SQLite3](http://www.sqlite.org/), and, at least
on Ubuntu, the sqlite3 development libraries 
(`sudo apt-get install libsqlite3-dev`). If you have specific installation
instructions for other platforms, please feel free to send a pull request
with changes to this README.

### Installing as a Gem

    gem install wesabot

### Installing from Git

Clone this repository, then `cd` to it and run `bundle install`.

## Usage

The first thing you need to do is to create a Campfire user for your bot,
and make sure that user has access to whichever room(s) you would like the bot
to appear in. Log into Campfire as that user and get the API token (click on
"My info" in the upper right corner).

Wesabot has four required parameters:

* subdomain - your Campfire subdomain
* api_token - the Campfire API token
* room - the room in which you'd like the bot to appear
* datauri - the sqlite3 database uri/path

These parameters can be passed in either via a YAML config file, or on the
command-line. See `config/wesabot.yml.sample` for a sample configuration file.

Examples:

    bin/wesabot -c config/wesabot.yml
    bin/wesabot -d example -r Sandbox -t ecca8793813bd3e5720d9d562285db --database /path/to/database.db

Run `wesabot --help` for usage information.

**A few important things to note:**

* The SQLite database does not need to exist initially--wesabot will create one
at the path you specify.
* On some systems (Ubuntu, at least) you will need to use the `--ssl-no-verify`
(`-k`) option, at least until the next release of [Faraday](https://github.com/technoweenie/faraday),
which includes [a fix](https://github.com/technoweenie/faraday/commit/2b9b798d07b95b3a3348e95c513fe42f5e21c6ee)
for looking up SSL certs in the system store. If you run wesabot and get the
error:

        /usr/lib/ruby/1.8/net/http.rb:1060:in `request': undefined method `closed?' for nil:NilClass (NoMethodError)

    That is the cause. (Run it again in verbose mode to see the SSL error.)


Once Wes (or whatever you decide to name your bot) is running, you can see a list of available commands by entering into Campfire:

    Wes, help

That list currently looks like:

    AirbrakePlugin:
     - resolve <error number>
         mark an error as resolved
     - unresolve <error number>
         mark an error as unresolved

    BookmarkPlugin:
     - bookmark: <name>
         bookmark the current location

    DebugPlugin:
     - <enable|disable> debugging
         enable or disable debug mode

    DeployPlugin:
     - what's on deck for <project>?
         shortlog of changes not yet deployed to production
     - what's on deck for <project> staging?
         shortlog of changes not yet deployed to staging

    GreetingPlugin:
     - (disable|turn off) greetings
         don't say hi when you log in (you grump)
     - (enable|turn on) greetings
         say hi when you log in
     - toggle greetings
         disable greetings if enabled, enable if disabled. You know--toggle.
     - catch me up|ketchup
         gives you a link to the point in the transcript where you last logged out

    HelpPlugin:
     - help
         this message

    ImageSearchPlugin:
     - (photo|image|picture) of <subject>
         find a new picture of <subject>
     - search (google|flickr) for a (photo|image|picture) of <subject>
         search the stated service for a new picture of <subject>

    ReloadPlugin:
     - reload
         update and reload Wes

    RemindMePlugin:
     - remind (me|<person>) [in] <time string> to <message>
         set up a reminder
     - remind (me|<person>) to <message> (in|on|at|next|this) <time string>
         set up a reminder
     - [list|show] [person]['s] reminders
         display current reminders for yourself or person
     - delete reminder <n>
         delete your reminder #n

    SMSPlugin:
     - set my sms address to: <address>
         set your sms address
     - set <person>'s sms address to
         set someone else's sms address
     - (sms|text|txt) <person>: <message>
         send an sms message
     - list sms addresses
         list all sms addresses

    TimePlugin:
     - time
         say the current time

    TweetPlugin:
     - tweet: <message>
         post <message> to the configured user's twitter account
     - save tweet: <message>
         save <message> for later
     - show tweets
         shows the queued tweets for the configured user's twitter account
     - show next tweet
         shows the oldest queued twitter message
     - post next tweet
         sends the oldest queued twitter message
     - post tweet <n>
         sends the <n>th tweet from the list
     - delete tweet <n>
         deletes the <n>th tweet from the list

    TwitterSearchPlugin:
     - what are (people|is everyone) saying about <subject>
         search twitter for tweets on <subject>
     - what's the word on <subject>
         search twitter for tweets on <subject>
