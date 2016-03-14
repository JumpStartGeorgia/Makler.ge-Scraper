# Provides interface to work with status.json, a file which stores information
# about the previous scrape run
class Status
  def initialize(file_path)
    @file = file_path

    unless File.exist? file
      create_new_file
      return
    end

    set_attributes_from_file
  end

  attr_accessor :file,
                :json_ids_to_process,
                :db_ids_to_process,
                :last_scraped_date

  def reset_file
    create_new_file
  end

  def update_last_scraped_date(new_date)
    @last_scraped_date = new_date if last_scraped_date < new_date
    update_file
  end

  def remove_db_id(id, locale)
    fail if db_ids_to_process[locale].nil?

    db_ids_to_process[locale].delete(id)

    update_file
  end

  def remove_json_id(id, locale)
    fail if json_ids_to_process[locale].nil?

    json_ids_to_process[locale].delete(id)

    update_file
  end

  def db_ids_for_locale?(locale)
    locale = locale.to_sym
    fail if db_ids_to_process[locale].nil?

    db_ids_to_process[locale].length > 0
  end

  def num_json_ids_to_process
    total = 0

    [:en, :ka].each do |locale|
      total += json_ids_to_process[locale].length
    end

    total
  end

  def save_new_posting_to_process(id, date)
    return if id.nil? || date.nil?

    post = {
      id: id,
      date: date
    }

    [:en, :ka].each do |locale|
      json_ids_to_process[locale] << post.clone
      db_ids_to_process[locale] << post.clone
    end

    update_file
  end

  private

  def set_attributes_from_file
    parsed_file = JSON.parse(File.read(file))

    date_string = parsed_file['last_scraped_date']
    if date_string.nil?
      @last_scraped_date = default_last_scraped_date
    else
      @last_scraped_date = Date.strptime(date_string)
    end
    @json_ids_to_process = parsed_file['ids_to_process']['json']
    @db_ids_to_process = parsed_file['ids_to_process']['db']
  end

  def create_new_file
    @json_ids_to_process = {
      en: [],
      ka: []
    }

    @db_ids_to_process = {
      en: [],
      ka: []
    }

    @last_scraped_date = default_last_scraped_date

    update_file
  end

  def default_last_scraped_date
    Date.today
  end

  def update_file
    File.open(file, 'w') { |f| f.write(to_json) }
  end

  def to_json
    {
      last_scraped_date: last_scraped_date,
      ids_to_process: {
        json: json_ids_to_process,
        db: db_ids_to_process
      }
    }.to_json
  end
end
