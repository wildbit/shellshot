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

      prepare_pipes
      self.pid = fork do
        close_reading_pipes
        redefine_stds
        system_exec(command)
      end

      begin
        wait_for(options[:timeout] || DEFAULT_TIMEOUT)
      rescue Timeout::Error => e
        terminate_child_process
        raise
      end

      true
    end

    def stderr_contents
      @stderr_contents ||= unless stderr_defined?
        @stderr_wr.close
        contents = @stderr_rd.read
        @stderr_rd.close
        contents
      else
        File.read(stderr_location)
      end
    end

    def stdout_contents
      @stdout_contents ||= unless stdout_defined?
        @stdout_wr.close
        contents = @stdout_rd.read
        @stdout_rd.close
        contents
      else
        File.read(stdout_location)
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

    def terminate_child_process
      if pid
        Process.kill("KILL", pid)
        Process.wait(pid) # reaping zombie processes. Not sure if correct.
      end
    end

    def redefine_stds
      $stdout.reopen(stdout_descriptor)
      $stderr.reopen(stderr_descriptor)
    end

    def stderr_location
      stdall_location || (options[:stderr] == false ? null_location : options[:stderr])
    end

    def stdout_location
      stdall_location || (options[:stdout] == false ? null_location : options[:stdout])
    end

    def stderr_descriptor
      stdall_descriptor || @stderr_wr || File.open(stderr_location, "w+")
    end

    def stdout_descriptor
      stdall_descriptor || @stdout_wr || File.open(stdout_location, "w+")
    end

    def stdall_descriptor
      if stdall_location
        @stdall_descriptor ||= File.open(stdall_location, "w+")
      end
    end

    def stderr_defined?
      !stderr_location.nil?
    end

    def stdout_defined?
      !stdout_location.nil?
    end

    def stdall_location
      options[:stdall] == false ? null_location : options[:stdall]
    end

    def close_reading_pipes
      @stderr_rd.close unless stderr_defined?
      @stdout_rd.close unless stdout_defined?
    end

    def prepare_pipes
      @stderr_rd, @stderr_wr = IO.pipe unless stderr_defined?
      @stdout_rd, @stdout_wr = IO.pipe unless stdout_defined?
    end

    def null_location
      "/dev/null"
    end

  end

  def self.exec(command, options = {})
    Shellshot::Command.new().exec(command, options)
  end

end
