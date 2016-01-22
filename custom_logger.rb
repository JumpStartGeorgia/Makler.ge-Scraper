# Logs all messages to files and stores in array for later usage (i.e. by error sheet)
class CustomLogger
  def initialize(name, log_file_path)
    @name = name
    @logger = Logger.new(log_file_path)

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
    end

    error_string = "--- #{name}: Errors ---\n"
    error_messages.each_with_index do |error_message, index|
      error_string << "#{index + 1}. #{error_message}\n"
    end

    error_string
  end

  private

  attr_reader :logger
end
