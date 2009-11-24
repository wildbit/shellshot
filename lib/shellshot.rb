require 'rubygems'
require 'tempfile'
require 'system_timer'

module Shellshot

  class CommandError < RuntimeError; end

  class Command

    alias_method :system_exec, :exec

    DEFAULT_TIMEOUT = 60 * 60 # 1 hour

    attr_accessor :pid, :status, :options

    def exec(command, options = {})

      self.options = options

      prepare_pipes if no_stderr?
      self.pid = fork do
        close_reading_pipe if no_stderr?
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
      SystemTimer.timeout(seconds) do
        Process.wait(pid)
        self.status = $?
        unless self.status.success?
          raise CommandError, stderr_contents
        end
      end
    end

    def close_stderr
      error_tempfile.close
    end

    def terminate_child_process
      if pid
        Process.kill("KILL", pid)
        Process.wait(pid) # reaping zombie processes. Not sure if correct.
      end
    end

    def redefine_stds(options)
      if stdall_location
        combined = File.open(stdall_location, "w+")
        $stdout.reopen(combined)
        $stderr.reopen(combined)
      else
        $stdout.reopen(File.open(stdout_location, "w+")) if stdout_location
        if no_stderr?
          $stderr.reopen(@wr)
        else
          $stderr.reopen(File.open(stderr_location, "w+"))
        end
      end
    end

    def stderr_location
      stdall_location || options[:stderr]
    end

    def no_stderr?
      !stderr_location
    end

    def stdout_location
      stdall_location || options[:stdout]
    end

    def stdall_location
      options[:stdall]
    end

    def close_reading_pipe
      @rd.close
    end

    def stderr_contents
      if no_stderr?
        @wr.close
        contents = @rd.read
        @rd.close
        contents
      else
        File.read(stderr_location)
      end
    end

    def prepare_pipes
      @rd, @wr = IO.pipe
    end

    def close_pipes
      @rd.close
      @wr.close
    end
  end

  def self.exec(command, options = {})
    Shellshot::Command.new().exec(command, options)
  end

end
