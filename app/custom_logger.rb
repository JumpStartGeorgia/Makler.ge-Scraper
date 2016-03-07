require_relative 'environment'

# Logs all messages to files and stores in array for later usage (i.e. by error sheet)
class CustomLogger
  def initialize(name, file_name)
    @name = name

    dir_name = 'log'
    Dir.mkdir dir_name unless File.exist?(dir_name)
    @logger = Logger.new("#{dir_name}/#{file_name}")

    @info_messages = []
    @warning_messages = []
    @error_messages = []
  end

  attr_reader :name,
              :info_messages,
              :warning_messages,
              :error_messages

  def info(message)
    logger.info(message)
    @info_messages << message
  end

  def warn(message)
    logger.warn(message)
    @warning_messages << message
  end

  def error(message)
    logger.error(message)
    @error_messages << message
  end

  def errors_to_s
    if error_messages.empty?
      error_string = "--- #{name}: No errors this time! ---"
      return "#{error_string}\n\n"
    end

    error_string = "--- #{name}: Errors ---\n\n"
    error_messages.each_with_index do |error_message, index|
      error_string << "#{index + 1}. #{error_message}\n"
    end

    "#{error_string}\n\n"
  end

  private

  attr_reader :logger
end
