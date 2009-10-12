
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib shellshot]))

require 'tmpdir'
require 'rubygems'
require 'ruby-debug'

Spec::Matchers.define :be_a_file do 
  match do |path|
    File.exists?(path)
  end
end

Spec::Matchers.define :contain do |contents|
  match do |path|
    File.exists?(path) && File.read(path).strip == contents
  end

  failure_message_for_should do |path|
    if File.exists?(path)
      "expected #{path} to contain '#{contents}', got '#{File.read(path).strip}'"
    else
      "expected #{path} to contain '#{contents}', but the file does not exist."
    end
  end
end

Spec::Runner.configure do |config|
  config.before(:each) do
    @tmpdir = Dir.mktmpdir 
    Dir.chdir(@tmpdir)
  end

  config.after(:each) do
    FileUtils.remove_entry_secure @tmpdir
  end

end



# EOF
