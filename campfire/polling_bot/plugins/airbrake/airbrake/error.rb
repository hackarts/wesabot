module Airbrake
  class Error
    include DataMapper::Resource
    property :id, Serial
    property :error_id, Integer, :required => true

    attr_accessor :field

    # Given a block of XML returned from the Airbrake API, return an
    # Airbrake::Error object
    def self.from_xml(xml)
      field = {}
      xml.xpath('./*').each do |node|
        content = node.content
        # convert to proper ruby types
        type = node.attributes['type'] && node.attributes['type'].value
        case type
        when "boolean"
          content = content == "true"
        when "datetime"
          content = Time.parse(content)
        when "integer"
          content = content.to_i
        end
        key = node.name.tr('-','_')
        field[key.to_sym] = content
      end
      error = new()
      error.field = field
      error.error_id = field[:id]
      return error
    end

    def summary
      "#{@field[:error_message]} at #{@field[:file]}:#{@field[:line_number]}"
    end

    def [](key)
      key = key.to_s.tr('-','_').to_sym
      @field[key]
    end

    def eql?(other)
      self.error_id.eql?(other.error_id)
    end

    def hash
      self.error_id.hash
    end
  end
end

# <?xml version="1.0" encoding="UTF-8"?>
# <groups type="array">
#   <group>
#     <created-at type="datetime">2011-09-02T18:36:59Z</created-at>
#     <notice-hash>af0bd1d1506128519c7327b0289db84e</notice-hash>
#     <project-id type="integer">42693</project-id>
#     <updated-at type="datetime">2011-09-02T18:51:39Z</updated-at>
#     <action nil="true"></action>
#     <resolved type="boolean">false</resolved>
#     <error-class>RuntimeError</error-class>
#     <error-message>RuntimeError: Test error to exercise chef-client error handler. To disable test, unset node[:test_error_handler] attribute</error-message>
#     <id type="integer">12830481</id>
#     <lighthouse-ticket-id type="integer" nil="true"></lighthouse-ticket-id>
#     <controller>component01.api-pub.ny1</controller>
#     <file>/var/cache/chef/cookbooks/daylife-ops/recipes/test-chef-handlers.rb</file>
#     <rails-env>prod</rails-env>
#     <line-number type="integer">16</line-number>
#     <most-recent-notice-at type="datetime">2011-09-02T18:51:39Z</most-recent-notice-at>
#     <notices-count type="integer">2</notices-count>
#   </group>
# </groups>
