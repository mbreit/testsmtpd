require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'gserver'
require 'mail'

Mail.defaults do
  delivery_method :smtp, { :address => "localhost", :port => 1025 }
end

describe TestSmtpd do
  it "should start a server on port 1025" do
    s = TestSmtpd.new {}
    s.start
    GServer.in_service?(1025).should be_true
    s.stopped?.should be_false
    s.stop
    s.join
    s.stopped?.should be_true
    GServer.in_service?(1025).should be_false
  end

  it "should recieve a mail message via smtp" do
    testmsg = ""
    thread = Thread.current
    s = TestSmtpd.new do |msg|
      testmsg << msg
      thread.run
    end
    s.start
    mail = Mail.deliver do
      from 'test@example.com'
      to 'to@example.com'
      subject 'Test'
      body 'Test'
    end
    s.stop
    s.join
    testmsg.should_not be_nil
    Mail.new(testmsg).should eq mail
  end

  it "should listen to a custom port given in options hash" do
    s = TestSmtpd.new(:port => 2525) { }
    s.start
    GServer.in_service?(1025).should be_false
    GServer.in_service?(2525).should be_true
    s.stop
    s.join
  end
end

