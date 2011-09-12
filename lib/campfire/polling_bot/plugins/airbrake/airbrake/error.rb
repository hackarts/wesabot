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
