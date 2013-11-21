require 'tempfile'

require_relative 'keylab_config'
require_relative 'keylab_logger'

class Keylab
  attr_accessor :auth_file, :key

  def initialize
    @command = ARGV.shift
    @key_id = ARGV.shift
    @key = ARGV.shift
    @auth_file = KeylabConfig.new.auth_file
    @hook_executable = KeylabConfig.new.hook_executable
  end

  def exec
    case @command
    when 'add-key'; add_key
    when 'rm-key';  rm_key
    when 'clear';  clear
    else
      $logger.warn "Attempt to execute invalid keylab command #{@command.inspect}."
      puts 'not allowed'
      false
    end
  end

  protected

  def add_key
    config = KeylabConfig.new
    $logger.info "Adding key #{@key_id} => #{@key.inspect}"
    auth_line = "command=\"#{@hook_executable} #{@key_id}\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{@key}"
    open(auth_file, 'a') { |file| file.puts(auth_line) }
  end

  def rm_key
    $logger.info "Removing key #{@key_id}"
    Tempfile.open('authorized_keys') do |temp|
      open(auth_file, 'r+') do |current|
        current.each do |line|
          temp.puts(line) unless line.include?("{@hook_executable} #{@key_id}\"")
        end
      end
      temp.close
      FileUtils.cp(temp.path, auth_file)
    end
  end

  def clear
    open(auth_file, 'w') { |file| file.puts '# Managed by #{@hook_executable}' }
  end
end