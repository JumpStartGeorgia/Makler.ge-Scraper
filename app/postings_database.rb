require_relative 'environment'

####################################################
# to load the jobs to a database, please have the following:
# - database.yml file with the following keys and the appropriate values
# - the user must have the ability to create database and tables
# - this database.yml file is not saved into the git repository so
#   passwords are not shared with the world
# - yml keys:
#     database:
#     username:
#     password:
#     encoding: utf8
#     host: localhost
#     port: 3306
#     reconnect: true

# - you will need to create the database
# - the tables will be created if they do not exist
####################################################

class PostingsDatabase
  def initialize(db_config_path, log)
    @log = log
    @db_config = get_db_config(db_config_path)

    @mysql = make_mysql_connection

    create_postings_table
  end

  attr_reader :db_config, :mysql, :log

  def query(sql)
    @mysql.query(sql)
  end

  def dump(db_dump_file)
    log.info '------------------------------'
    log.info 'dumping database'
    log.info '------------------------------'

    Subexec.run "mysqldump --single-transaction -u'#{db_config["username"]}' -p'#{db_config["password"]}' #{db_config["database"]} | gzip > \"#{db_dump_file}\" "
  end

  def close
    mysql.close if mysql
  end

  def number_postings_by_date
    output_query_result_to_console(
      query('SELECT date, COUNT(id) FROM postings GROUP BY date;')
    )
  end

  def ids_for_date(date)
    date_str = date.strftime('%Y-%m-%d')
    abort if date_str.nil?
    sql = "SELECT posting_id FROM postings WHERE date LIKE '#{date_str}%';"

    query(sql).map { |row| row['posting_id'] }
  end

  private

  def get_db_config(db_config_path)
    unless File.exist?(db_config_path)
      msg = "The #{db_config_path} does not exist"
      log.error(msg)
      abort(msg)
    end

    YAML.load(ERB.new(File.read(db_config_path)).result)
  end

  def make_mysql_connection
    Mysql2::Client.new(
      host: db_config['host'],
      port: db_config['port'],
      database: db_config['database'],
      username: db_config['username'],
      password: db_config['password'],
      encoding: db_config['encoding'],
      reconnect: db_config['reconnect'])
  end

  def create_postings_table
    query(
      "CREATE TABLE IF NOT EXISTS `postings` (\
      `id` int(11) NOT NULL AUTO_INCREMENT,\
      `posting_id` varchar(255) not null,\
      `locale` varchar(10) not null,\
      `source` varchar(255) not null,\
      `type` varchar(255) default null,\
      `property_type` varchar(255) default null,\
      `date` date not null,\
      `additional_info` text default null,\
      `daily_rent` varchar(255) default null,\
      `for_rent` varchar(255) default null,\
      `for_sale` varchar(255) default null,\
      `for_lease` varchar(255) default null,\
      `est_lease_price` varchar(255) default null,\
      `rent_price` numeric(15,2) default null,\
      `rent_price_currency` varchar(10) default null,\
      `rent_price_sq_meter` numeric(15,2) default null,\
      `rent_price_dollars` numeric(15,2) default null,\
      `rent_price_sq_meter_dollars` numeric(15,2) default null,\
      `rent_price_exchange_rate_to_dollars` numeric(15,5) default null,\
      `sale_price` numeric(15,2) default null,\
      `sale_price_currency` varchar(10) default null,\
      `sale_price_sq_meter` numeric(15,2) default null,\
      `sale_price_dollars` numeric(15,2) default null,\
      `sale_price_sq_meter_dollars` numeric(15,2) default null,\
      `sale_price_exchange_rate_to_dollars` numeric(15,5) default null,\
      `space` numeric(15,2) default null,\
      `space_measurement` varchar(20) default null,\
      `land` numeric(15,2) default null,\
      `land_measurement` varchar(20) default null,\
      `renovation` varchar(255) default null,\
      `view` varchar(255) default null,\
      `metro` varchar(255) default null,\
      `project` varchar(255) default null,\
      `place_condition` varchar(255) default null,\
      `function` varchar(255) default null,\
      `address` varchar(1000) default null,\
      `address_city` varchar(255) default null,\
      `address_area` varchar(255) default null,\
      `address_district` varchar(255) default null,\
      `address_street` varchar(255) default null,\
      `address_number` varchar(255) default null,\
      `phone` varchar(255) default null,\
      `cadastral` varchar(255) default null,\
      `all_floors` numeric(8,2) default null,\
      `floor` numeric(8,2) default null,\
      `rooms` numeric(8,2) default null,\
      `bedrooms` numeric(8,2) default null,\
      `conference_room` numeric(8,2) default null,\
      `suites` numeric(8,2) default null,\
      `wc` numeric(8,2) default null,\
      `bathroom` numeric(8,2) default null,\
      `shower` numeric(8,2) default null,\
      `fireplace` numeric(8,2) default null,\
      `air_conditioner` numeric(8,2) default null,\
      `balcony` numeric(8,2) default null,\
      `veranda` numeric(8,2) default null,\
      `loft` numeric(8,2) default null,\
      `bodrum` numeric(8,2) default null,\
      `mansard` numeric(8,2) default null,\
      `parking` numeric(8,2) default null,\
      `garage` numeric(8,2) default null,\
      `dist_from_tbilisi` numeric(8,2) default null,\
      `dist_from_cent_street` numeric(8,2) default null,\
      `box` numeric(8,2) default null,\
      `buildings` numeric(8,2) default null,\
      `administration_building` numeric(8,2) default null,\
      `workroom` numeric(8,2) default null,\
      `stockroom` numeric(8,2) default null,\
      `coefficient_k1` numeric(8,2) default null,\
      `coefficient_k2` numeric(8,2) default null,\
      `created_at` datetime,\
      PRIMARY KEY `Index 1` (`id`),\
      KEY `Index 2` (`posting_id`),\
      KEY `Index 3` (`locale`),\
      KEY `Index 4` (`source`),\
      KEY `Index 5` (`type`),\
      KEY `Index 6` (`property_type`),\
      KEY `Index 7` (`rent_price_dollars`),\
      KEY `Index 8` (`rent_price_sq_meter_dollars`),\
      KEY `Index 9` (`sale_price_dollars`),\
      KEY `Index 10` (`sale_price_sq_meter_dollars`),\
      KEY `Index 11` (`space`),\
      KEY `Index 12` (`land`),\
      KEY `Index 13` (`address_city`),\
      KEY `Index 14` (`address_area`),\
      KEY `Index 15` (`address_district`),\
      KEY `Index 16` (`address_street`),\
      CONSTRAINT uc_id_locale UNIQUE (posting_id, locale)\
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
  end

  def output_query_result_to_console(query_result)
    query_result.each do |row|
      puts row
    end
  end
end
