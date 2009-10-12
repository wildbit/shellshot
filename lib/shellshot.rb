require 'english'

module Shellshot
  
  class Command

    alias_method :system_exec, :exec

    DEFAULT_TIMEOUT = 60 #minutes

    attr_accessor :pid, :status

    def exec(command, options = {})
      self.pid = fork do
        redefine_stds(options)
        system_exec(command)
      end

      begin
        wait_for(options[:timeout] || DEFAULT_TIMEOUT)
      rescue Timeout::Error => e
        terminate_child_process
        raise
      end
    end

    private

    def wait_for(seconds)
      Timeout.timeout(seconds) do
        Process.wait(pid)   
        self.status = $CHILD_STATUS
      end
    end

    def terminate_child_process
      if pid 
        Process.kill("KILL", pid)
        Process.wait(pid) # reaping zombie processes. Not sure if correct.
      end
    end

    def redefine_stds(options)
      $stdout.reopen(File.open(options[:stdout], "w+")) if options[:stdout]
      $stderr.reopen(File.open(options[:stderr], "w+")) if options[:stderr]

      if options[:stdall]
        combined = File.open(options[:stdall], "w+")
        $stdout.reopen(combined)
        $stderr.reopen(combined)
      end
    end
  end

  def self.exec(command, options = {})
    Shellshot::Command.new().exec(command, options)
  end

end
