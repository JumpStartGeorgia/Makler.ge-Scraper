require_relative 'environment'

# Combines all errors from all logs
class ErrorSheet
  def initialize(logs)
    @logs = logs
  end

  def to_s
    <<-STRING
      #{log_errors_to_s}
    STRING
  end

  private

  attr_reader :logs

  def log_errors_to_s
    log_errors = ''
    logs.each do |log|
      log_errors += log.errors_to_s
    end

    log_errors
  end
end
