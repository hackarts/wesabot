require 'spec_helper'

describe Campfire::PollingBot do
  before do
    @bot = FakeBot.new
  end

  it 'recognizes commands addressed to itself' do
    messages = ["wes", "wes?", "wes hi", "wes, hi", "hi, wes", "hi wes", 
                "wes: hi"]
    messages.each do |m|
      @bot.addressed_to_me?(Campfire::TextMessage.new(:body => m)).should be_true
    end
  end 

  it 'does not recognize commands not addressed to itself' do
    messages = ["hi", "western", "weswes?"]
    messages.each do |m|
      @bot.addressed_to_me?(Campfire::TextMessage.new(:body => m)).should be_false
    end
  end 

end