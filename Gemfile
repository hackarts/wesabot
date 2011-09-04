source :gemcutter

gem "capistrano"
gem "railsless-deploy", :require => nil
gem "tinder", :git => "git://github.com/collectiveidea/tinder.git"
gem "data_mapper", "~>1.1"
gem "dm-sqlite-adapter", "~>1.1"
gem "daemons"
gem "i18n"
gem "firering", "~>1.0.8", :git => "git://github.com/indirect/firering.git"

# load plugin gemspecs
gemspecs = Dir.glob(File.dirname(__FILE__) + "/campfire/polling_bot/plugins/*/*.gemspec")
gemspecs.each {|g| gemspec :path => File.dirname(g)}

group :test do
  gem "rspec", "~> 2.6.0"
  gem "rake" # needed for RSpec::Core::RakeTask
  gem "ruby-debug"
end