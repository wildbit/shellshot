require File.expand_path(File.dirname(__FILE__) + '/profile_helper')

class ShellshotProfile < Test::Unit::TestCase

  def setup
    RubyProf.measure_mode = RubyProf::WALL_TIME
  end

  def benchmark(title, &block)
    puts "#{title} \n"
    time = Benchmark.measure &block
    puts "Time spent: #{time.to_s.squeeze.strip} \n"
  end

  def cmd
    %q[ruby -e '10000.times { puts "a" }']
  end

  def test_builtin_exec
    profile "system" do
      system("#{cmd} > /dev/null")
    end
  end

  def test_executing_large_stdout
    profile "Shellshot" do
      Shellshot.exec cmd #, :stdout => '/dev/null'
    end
  end

  def profile(name, &block)
    time = Benchmark.measure do
      result = RubyProf.profile &block
      printer = RubyProf::FlatPrinter.new(result)
      puts "\n#== #{name} ==\n"
      printer.print(STDOUT, :min_percent => 10)
    end
    puts "Time spent: #{time.to_s.squeeze.strip} \n"
  end

end
