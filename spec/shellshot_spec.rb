
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

end

# EOF
