
require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Shellshot do

  it "should execute the given command" do
    Shellshot.exec("touch file")
    "file".should be_a_file
  end

  it "should pipe the out to the right file" do
    Shellshot.exec(%q[ruby -e 'puts "Hello World"'], :stdout => "file")
    "file".should contain("Hello World")
  end

  it "should pipe the err to the right file" do
    Shellshot.exec(%q[ruby -e '$stderr << "error"'], :stderr => "file")
    "file".should contain("error")
  end

  it "should pipe everything to the right file" do
    Shellshot.exec(%q[ruby -e '$stderr << "Hello "; puts "World"'], :stdall => "file")
    "file".should contain("Hello World")
  end

  it "should cancel execution on time if timeout provided" do
    lambda { Shellshot.exec %q[ruby -e 'sleep 10000'], :timeout => 1 }.should raise_error(Timeout::Error)
  end

  it "should raise error if command returned something else." do
    lambda { Shellshot.exec %q[ruby -e '$stderr << "problem"; exit 1;'] }.should raise_error(Shellshot::CommandError, "problem")
  end

  it "should capture stdout by default" do
    cmd = Shellshot::Command.new
    cmd.exec %q[ruby -e '$stdout << "test"']
    cmd.stdout_contents.should == "test"
  end

  it "should capture stderr by default" do
    cmd = Shellshot::Command.new
    cmd.exec %q[ruby -e '$stderr << "test"']
    cmd.stderr_contents.should == "test"
  end

  it "should discard stdout and stderr if false passed" do
    cmd = Shellshot::Command.new
    cmd.exec %q[ruby -e '$stderr << "test"; $stdout << "test"'], :stdout => false, :stderr => false
    cmd.stderr_contents.should == ""
    cmd.stdout_contents.should == ""
  end

  it "should discard stdout and stderr if stdall = false" do
    cmd = Shellshot::Command.new
    cmd.exec %q[ruby -e '$stderr << "test"; $stdout << "test"'], :stdall => false
    cmd.stderr_contents.should == ""
    cmd.stdout_contents.should == ""
  end

end

# EOF
