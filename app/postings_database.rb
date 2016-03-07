class PostingsDatabase
  def initialize(db_config_path)
    # make sure the file exists
    unless File.exists?(db_config_path)
      log.error "The #{db_config_path} does not exist"
      exit
    end

    @db_config = YAML.load(ERB.new(File.read(db_config_path)).result)

    @mysql = Mysql2::Client.new(:host => db_config["host"], :port => db_config["port"], :database => db_config["database"],
                                :username => db_config["username"], :password => db_config["password"],
                                :encoding => db_config["encoding"], :reconnect => db_config["reconnect"])
  end

  attr_reader :db_config, :mysql

  def query(sql)
    @mysql.query(sql)
  end

  def dump(log, db_dump_file)
    log.info '------------------------------'
    log.info 'dumping database'
    log.info '------------------------------'

    Subexec.run "mysqldump --single-transaction -u'#{db_config["username"]}' -p'#{db_config["password"]}' #{db_config["database"]} | gzip > \"#{db_dump_file}\" "
  end

  def number_postings_by_date
    output_query_result_to_console(
      query('SELECT date, COUNT(id) FROM postings GROUP BY date;')
    )
  end

  def close
    mysql.close if mysql
  end

  private

  def output_query_result_to_console(query_result)
    query_result.each do |row|
      puts row
    end
  end
end
