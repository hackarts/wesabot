require 'nokogiri'
require 'rest-client'

module Airbrake
  class API
    def initialize(domain, auth_token)
      @host = "#{domain}.airbrakeapp.com"
      @auth_token = auth_token
    end

    def resolve_error(error_id, resolved=true)
      api_put("/errors/#{error_id}", {}, :group => {:resolved => resolved})
    end

    # Fetch errors from Airbrake.
    # Their API returns errors in pages of 30 at a time, so keep fetching
    # until we don't get anything.
    def errors(show_resolved=false)
      options = {}
      options[:show_resolved] = 1 if show_resolved
      page = 1
      errors = []
      begin
        options[:page] = page
        doc = Nokogiri::XML(api_get("/errors.xml", options))
        new_errors = doc.xpath("/groups/group").map {|node| Airbrake::Error.from_xml(node) }
        errors += new_errors
        page += 1
      end while new_errors.any?
      return errors
    end

    def error_url(error)
      error_id = error.is_a?(Airbrake::Error) ? error.error_id : error
      "https://#{@host}/errors/#{error_id}"
    end

    private

    def api_uri(endpoint, query = {})
      query = {:auth_token => @auth_token}.update(query)
      uri = URI::HTTPS.build(:host => @host, :path => endpoint, :query => to_query(query))
      return uri.to_s
    end

    # convert a hash of param to a query string
    def to_query(params)
      params.map{|k,v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')
    end

    def api_get(endpoint, query = {})
      RestClient.get(api_uri(endpoint, query))
    end

    def api_put(endpoint, query = {}, params = {})
      return RestClient.put(api_uri(endpoint, query), params)
    rescue RestClient::Exception => e
      return e.response
    end
  end
end