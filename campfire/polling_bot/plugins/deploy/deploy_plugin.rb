require 'open-uri'

# Plugin to get a list of commits that are on deck to be deployed
class DeployPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true

  def process(message)
    case message.command
    when /deploy\s([^\s\!]+)(?:(?: to)? (staging|nine|production))?( with migrations)?/
      project, env, migrate = $1, $2, $3
      name = env ? "#{project} #{env}" : project
      env ||= "production"

      if not projects.any?
        bot.say("Sorry #{message.person}, I don't know about any projects. Please configure the deploy plugin.")
        return HALT
      end

      project ||= default_project
      if project.nil?
        bot.say("Sorry #{message.person}, I don't have a default project. Here are the projects I do know about:")
        bot.paste(projects.keys.sort.join("\n"))
        return HALT
      end
      project.downcase!

      info = project_info(project)
      if info.nil?
        bot.say("Sorry #{message.person}, I don't know anything about #{name}. Here are the projects I do know about:")
        bot.paste(projects.keys.sort.join("\n"))
        return HALT
      end

      bot.say("Okay, trying to deploy #{name}...")

      begin
        deploy = migrate ? "deploy:migrations" : "deploy"
        git(project, "bundle exec cap #{env} #{deploy}")
      rescue => e
        bot.log_error(e)
        bot.say("Sorry #{message.person}, I couldn't deploy #{name}.")
        return HALT
      end

      bot.say("Done.")
      return HALT

    when /on deck(?: for ([^\s\?]+)( staging)?)?/
      project, staging = $1, $2
      name = staging ? "#{project} staging" : project

      if not projects.any?
        bot.say("Sorry #{message.person}, I don't know about any projects. Please configure the deploy plugin.")
        return HALT
      end

      project ||= default_project
      if project.nil?
        bot.say("Sorry #{message.person}, I don't have a default project. Here are the projects I do know about:")
        bot.paste(projects.keys.sort.join("\n"))
        return HALT
      end
      project.downcase!

      info = project_info(project)
      if info.nil?
        bot.say("Sorry #{message.person}, I don't know anything about #{name}. Here are the projects I do know about:")
        bot.paste(projects.keys.sort.join("\n"))
        return HALT
      end

      range = nil
      begin
        range = "#{deployed_revision(project, staging)}..HEAD"
        logger.debug "asking for shortlog in range #{range}"
        shortlog = project_shortlog(project, range)
      rescue => e
        bot.log_error(e)
        bot.say("Sorry #{message.person}, I couldn't get what's on deck for #{name}.")
        return HALT
      end

      if shortlog.nil? || shortlog =~ /\A\s*\Z/
        bot.say("There's nothing on deck for #{name} right now.")
        return HALT
      end

      bot.say("Here's what's on deck for #{name}:")
      bot.paste("$ git shortlog #{range}\n\n#{shortlog}")

      return HALT
    end
  end

  def help
    help_lines = [
      ["what's on deck for <project>?", "shortlog of changes not yet deployed to production"],
      ["what's on deck for <project> staging?", "shortlog of changes not yet deployed to staging"],
    ]
    if default_project
      help_lines << ["what's on deck?", "shortlog of changes not yet deployed to #{default_project}"]
    end
    return help_lines
  end

  def projects
    (config && config['projects']) || {}
  end

  def default_project
    (config && config['default_project']) ||
      (projects.size == 1 ? projects.keys.first : nil)
  end

private

  def project_info(project)
    projects[project]
  end

  def project_shortlog(project, treeish)
    info = project_info(project)
    return nil if info.nil?

    return git(project, "git shortlog #{treeish}")
  end

  def deployed_revision(project, staging = false)
    info = project_info(project)
    return nil if info.nil?

    host = staging ? info['staging'] : info['url']
    return nil if host.nil?

    return open("http://#{host}/REVISION").read.chomp
  end

  def repository_path(project)
    File.expand_path File.join(config["repository_base_path"], "#{project}")
  end

  def git(project, cmd)
    dir = repository_path(project)
    out = Dir.chdir(dir) do
      # don't want output from the pull
      system("git pull")
      `#{cmd}`
    end

    unless $?.exitstatus.zero?
      raise "attempt to run `#{cmd}` in #{dir} failed with status #{$?.exitstatus}\n#{out}"
    end

    return out
  end
end
