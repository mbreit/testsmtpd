require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
end

