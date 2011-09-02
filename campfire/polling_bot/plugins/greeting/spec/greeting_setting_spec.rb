require 'spec_helper'

describe GreetingSetting do
  before do
    @bot = FakeBot.new
    User.all.destroy
    GreetingSetting.all.destroy
  end

  describe ".for_user" do
    context "when the user has no setting" do
      before do
        @user = User.create(:name => "Marc")
      end

      it "returns nil" do
        described_class.for_user(@user).should be_nil
      end
    end

    context "when the user has a setting by name only" do
      before do
        @user = User.create(:name => "Bob")
        @gs = described_class.create(:person => "Bob")
      end

      it "returns the greeting setting" do
        described_class.for_user(@user).should == @gs
      end

      it "associates the greeting setting with the user" do
        lambda { described_class.for_user(@user) }.
          should change { @gs.reload.user }.
                  from(nil).to(@user)
      end
    end

    context "when the user has the same name as another with an associated setting" do
      before do
        @user = User.create(:name => "Sam")
        @other = User.create(:name => "Sam")
        @gs = described_class.create(:person => "Sam", :user => @other)
      end

      it "returns nil" do
        described_class.for_user(@user).should be_nil
      end
    end

    context "when the user has an associated greeting setting" do
      before do
        @user = User.create(:name => "Coda")
        @gs = described_class.create(:person => "Coda", :user => @user)
      end

      it "returns the associated greeting setting" do
        described_class.for_user(@user).should == @gs
      end
    end
  end
end
