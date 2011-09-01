# used by ImageSearchPlugin
require 'dm-core'

class DisplayedImage
  include DataMapper::Resource
  property :id,  Serial
  property :uri, String, :index => true
end