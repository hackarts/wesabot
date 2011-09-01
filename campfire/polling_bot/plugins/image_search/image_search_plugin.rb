require 'httparty'
require 'google-search'

# plugin to send a tweet to a Twitter account
class ImageSearchPlugin < Campfire::PollingBot::Plugin
  priority 1
  accepts :text_message, :addressed_to_me => true

  def process(message)
    searched = false

    case message.command
    when /(google|flickr)\sfor\sa\s(?:photo|image|picture)\s+of:?\s+(?:a:?\s+)?\s*("?)(.*?)\1$/i
      subject = $3
      photo = next_photo(subject, $1)
      searched = true
    when /(?:photo|image|picture)\s+of:?\s+(?:a:?\s+)?\s*("?)(.*?)\1$/i
      subject = $2
      photo = next_photo(subject)
      searched = true
    end

    if searched
      if photo
        DisplayedImage.create(:uri => photo)
        bot.say(photo)
      else
        bot.say("Couldn't find anything for \"#{subject}\"")
      end
      return HALT
    end
  end

  # return array of available commands and descriptions
  def help
    [
      ['(photo|image|picture) of <subject>', "find a new picture of <subject>"],
      ['search (google|flickr) for a (photo|image|picture) of <subject>', "search the stated service for a new picture of <subject>"]
    ]
  end

private

  def next_photo(subject, sources = %w(google flickr))
    next_photo = nil

    if sources == ["google"] || (sources.include?("google") && bot.config.google_api_key)
      # google search lazy-fetches pages of results, so we only search as far as we have to
      if image = query_google(subject).find{|i| !DisplayedImage.first(:uri => i.uri) }
        next_photo ||= image.uri
      end
    end

    if sources.include?("flickr")
      next_photo ||= query_flickr(subject).find{|u| !DisplayedImage.first(:uri => u) }
    end

    return next_photo
  end

  def query_google(subject)
    unless bot.config.google_api_key
      bot.say("I don't have a Google Search API key. " +
        "Please add it to my config with the key 'google_api_key'.")
      return []
    end

    logger.debug("Searching Google Images for #{subject}")
    results = Google::Search::Image.new(
      :query => subject,
      :api_key => bot.config.google_api_key,
      :image_type => :photo,
      :safety_level => :off
    )

    logger.debug("Got response #{results.inspect}")
    return results || []
  end

  def query_flickr(subject)
    options = {:query => {:q => "select * from flickr.photos.search where text=\"#{subject}\""} }
    logger.debug("YQL query #{options[:query][:q]}")

    if proxy = (config && config['proxy']) || ENV['HTTP_PROXY']
      proxy_uri = URI.parse(proxy)
      options.update(:http_proxyaddr => proxy_uri.host, :http_proxyport => proxy_uri.port)
    end

    response = HTTParty.get("http://query.yahooapis.com/v1/public/yql", options)
    logger.debug("Got response #{response.parsed_response.inspect}")
    case response.code
    when 200
      return [] if response["query"]["yahoo:count"] == "0" || response["query"]["results"].nil?
      photos = response["query"]["results"]["photo"]
      photos = [photos] if photos.is_a?(Hash)
      return photos.map {|p| "http://farm%s.static.flickr.com/%s/%s_%s.jpg?v=0" % [p['farm'], p['server'], p['id'], p['secret']]}
    when 403
      bot.say("Sorry, we seem to have hit our query limit for the day.")
      return []
    else
      bot.say("Hmm...didn't work. Got this response:")
      bot.paste(response.body)
      return nil
    end
  end
end
