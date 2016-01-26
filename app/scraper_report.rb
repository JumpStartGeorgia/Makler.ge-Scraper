require 'mail'
require_relative '../config/mail_config'

# Shares statistics about scraper run
class ScraperReport
  def initialize(statistics_sheet, error_sheet)
    @date = Time.now.strftime('%F')
    @statistics_sheet = statistics_sheet
    @error_sheet = error_sheet
  end

  def send_email
    puts 'sending scraper report email'

    mail = Mail.new do
      from    ENV['FEEDBACK_FROM_EMAIL']
      to      ENV['FEEDBACK_TO_EMAIL']
      subject 'Makler.ge Scraper Report'
    end

    mail[:body] = body

    mail.deliver!
  end

  private

  attr_reader :date, :statistics_sheet, :error_sheet

  def body
    <<-REPORT_BODY
    Makler.Ge Scraper: Scrape Report
    Date: #{date}

    #{statistics_sheet.to_s}

    #{error_sheet.to_s}
    REPORT_BODY
  end
end
