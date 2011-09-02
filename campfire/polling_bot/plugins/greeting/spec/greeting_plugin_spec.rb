require 'spec_helper'

describe GreetingPlugin do
  before do
    GreetingSetting.all.destroy
    User.all.destroy
    @plugin = described_class.new
    @plugin.stub!(:catch_up_link).and_return("http://example.com")
  end

  it 'greets users as they enter the room by default' do
    entering.should make_wes_say(/^Hey John/i)
  end

  it 'allows disabling greetings per user' do
    say('wes, disable greetings')
    leave
    entering.should_not make_wes_say_anything
  end

  it 'confirms disabling greetings per user' do
    saying('wes, disable greetings').
      should make_wes_say("OK, I've disabled greetings for you, John")
  end

  it 'allows re-enabling greetings per user' do
    say('wes, disable greetings')
    say('wes, enable greetings')
    leave
    entering.should make_wes_say(/^Hey John/i)
  end

  it 'confirms re-enabling greetings per user' do
    say('wes, disable greetings')
    saying('wes, enable greetings').
      should make_wes_say("OK, I've enabled greetings for you, John")
  end

  it 'allows toggling greetings per user' do
    say('wes, enable greetings')
    say('wes, toggle greetings')
    leave
    entering.should_not make_wes_say_anything
  end

  it 'confirms toggling greetings per user' do
    say('wes, enable greetings')
    saying('wes, toggle greetings').
      should make_wes_say("OK, I've disabled greetings for you, John")
  end
end