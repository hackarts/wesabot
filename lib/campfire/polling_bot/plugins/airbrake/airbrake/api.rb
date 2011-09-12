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

    def errors(show_resolved=false)
      doc = Nokogiri::XML(api_get("/errors.xml", :show_resolved => show_resolved))
      doc.xpath("/groups/group").map {|node| Airbrake::Error.from_xml(node) }
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