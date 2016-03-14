require_relative 'environment'

def environment_is_production
  return ENV['ENVIRONMENT'] == 'production'
end

def json_template
  json = {}
  json[:posting_id] = nil
  json[:locale] = nil
  json[:type] = nil
  json[:property_type] = nil
  json[:date] = nil
  json[:additional_info] = nil

  json[:details] = {}
  json[:details][:daily_rent] = nil
  json[:details][:for_rent] = nil
  json[:details][:for_sale] = nil
  json[:details][:for_lease] = nil
  json[:details][:est_lease_price] = nil
  json[:details][:rent_price] = nil
  json[:details][:rent_price_currency] = nil
  json[:details][:rent_price_sq_meter] = nil
  json[:details][:rent_price_dollars] = nil
  json[:details][:rent_price_sq_meter_dollars] = nil
  json[:details][:rent_price_exchange_rate_to_dollars] = nil
  json[:details][:sale_price] = nil
  json[:details][:sale_price_currency] = nil
  json[:details][:sale_price_sq_meter] = nil
  json[:details][:sale_price_dollars] = nil
  json[:details][:sale_price_sq_meter_dollars] = nil
  json[:details][:sale_price_exchange_rate_to_dollars] = nil
  json[:details][:space] = nil
  json[:details][:space_measurement] = nil
  json[:details][:land] = nil
  json[:details][:land_measurement] = nil
  json[:details][:renovation] = nil
  json[:details][:metro] = nil
  json[:details][:view] = nil
  json[:details][:project] = nil
  json[:details][:condition] = nil
  json[:details][:function] = nil
  json[:details][:address] = nil
  json[:details][:address_city] = nil
  json[:details][:address_area] = nil
  json[:details][:address_district] = nil
  json[:details][:address_street] = nil
  json[:details][:address_number] = nil
  json[:details][:phone] = nil
  json[:details][:cadastral] = nil

  json[:specs] = {}
  json[:specs][:all_floors] = nil
  json[:specs][:floor] = nil
  json[:specs][:rooms] = nil
  json[:specs][:bedrooms] = nil
  json[:specs][:conference_room] = nil
  json[:specs][:suites] = nil
  json[:specs][:wc] = nil
  json[:specs][:bathroom] = nil
  json[:specs][:shower] = nil
  json[:specs][:fireplace] = nil
  json[:specs][:air_conditioner] = nil
  json[:specs][:balcony] = nil
  json[:specs][:veranda] = nil
  json[:specs][:loft] = nil
  json[:specs][:bodrum] = nil
  json[:specs][:mansard] = nil
  json[:specs][:parking] = nil
  json[:specs][:garage] = nil
  json[:specs][:dist_from_tbilisi]= nil
  json[:specs][:dist_from_cent_street] = nil
  json[:specs][:box] = nil
  json[:specs][:buildings] = nil
  json[:specs][:administration_building] = nil
  json[:specs][:workroom] = nil
  json[:specs][:stockroom] = nil
  json[:specs][:coefficient_k1] = nil
  json[:specs][:coefficient_k2] = nil

  return json
end

def create_directory(file_path)
	if !file_path.nil? && file_path != "."
		FileUtils.mkpath(file_path)
	end
end

# get the parent folder for the provided id
# - the folder is the id minus it's last 3 digits
def get_parent_id_folder(id)
  id.to_s[0..id.to_s.length-4]
end

def get_locale_key(locale_id)
  match = @locales.keys.select{|x| @locales[x][:id] == locale_id}.first
  if !match.nil?
    return match
  end
end

# determine the type of page being viewed
def get_page_type(text, locale_id)
  key = get_locale_key(locale_id)
  if !key.nil?
    type = @locales[key][:types].values.select{|x| text.downcase.index(x) == 0}
    if !type.nil?
      return type.first
    end
  end
end

# determine the property type of page being viewed
def get_property_type(text, locale_id)
  key = get_locale_key(locale_id)
  if !key.nil?
    type = @locales[key][:property_types].values.select{|x| !text.downcase.index(x).nil?}
    if !type.nil?
      return type.first
    end
  end
end

# pull out a query parameter value for a particular key
def get_param_value(url, key)
  value = nil
  index_q = url.index('?')
  if !index_q.nil?
    url_params = url.split('?').last

    if !url_params.nil?
      params = url_params.split('&')

      if !params.nil?
        param = params.select{|x| x.index(key + '=') == 0}
        if !param.nil?
          value = param.first.split('=')[1]
        end

      end
    end
  end

  return value
end

def posting_is_duplicate(post_id, post_date)
  (post_date == @earliest_day_to_scrape) &&
    (@saved_ids_for_last_scraped_date.include? post_id)
end

# pull out the id of each property from the link
def pull_out_ids(search_results)
  search_results.each do |search_result|
    image_link = search_result.css('div.ann_thmb a')[0]
    post_id = get_param_value(image_link['href'], 'id')

    post_date_str = search_result.css('.fge .float_right .orange_num')[0].text
    post_date = Date.strptime(post_date_str, '%d.%m.%Y')

    next if post_id.nil?

    if post_date < @earliest_day_to_scrape || reached_max_num_ids_to_scrape
      @finished_scraping_new_post_ids = true
      break
    end

    @num_ids_scraped += 1

    if posting_is_duplicate(post_id, post_date)
      @statistics_sheet.increase_num_duplicate_postings_found_by_1
      next
    end

    @status.save_new_posting_to_process(post_id, post_date)
  end
end


# create sql for insert statements
def create_sql_insert(mysql, json, source, locale)
  fields = []
  values = []
  sql = nil

  fields << 'source'
  values << source

  fields << 'locale'
  values << locale

  fields << 'created_at'
  values << Time.now.strftime('%Y-%m-%d %H:%M:%S')

  if !json["posting_id"].nil?
    fields << 'posting_id'
    values << json["posting_id"]
  end
  if !json["type"].nil?
    fields << 'type'
    values << json["type"]
  end
  if !json["property_type"].nil?
    fields << 'property_type'
    values << json["property_type"]
  end
  if !json["date"].nil?
    fields << 'date'
    values << json["date"]
  end
  if !json["additional_info"].nil?
    fields << 'additional_info'
    values << json["additional_info"]
  end

  if !json["details"]["daily_rent"].nil?
    fields << 'daily_rent'
    values << json["details"]["daily_rent"]
  end
  if !json["details"]["for_rent"].nil?
    fields << 'for_rent'
    values << json["details"]["for_rent"]
  end
  if !json["details"]["for_sale"].nil?
    fields << 'for_sale'
    values << json["details"]["for_sale"]
  end
  if !json["details"]["for_lease"].nil?
    fields << 'for_lease'
    values << json["details"]["for_lease"]
  end
  if !json["details"]["est_lease_price"].nil?
    fields << 'est_lease_price'
    values << json["details"]["est_lease_price"]
  end
  if !json["details"]["rent_price"].nil?
    fields << 'rent_price'
    values << json["details"]["rent_price"]
  end
  if !json["details"]["rent_price_currency"].nil?
    fields << 'rent_price_currency'
    values << json["details"]["rent_price_currency"]
  end
  if !json["details"]["rent_price_exchange_rate_to_dollars"].nil?
    fields << 'rent_price_exchange_rate_to_dollars'
    values << json["details"]["rent_price_exchange_rate_to_dollars"]
  end
  if !json["details"]["rent_price_dollars"].nil?
    fields << 'rent_price_dollars'
    values << json["details"]["rent_price_dollars"]
  end
  if !json["details"]["rent_price_sq_meter"].nil?
    fields << 'rent_price_sq_meter'
    values << json["details"]["rent_price_sq_meter"]
  end
  if !json["details"]["rent_price_sq_meter_dollars"].nil?
    fields << 'rent_price_sq_meter_dollars'
    values << json["details"]["rent_price_sq_meter_dollars"]
  end
  if !json["details"]["sale_price"].nil?
    fields << 'sale_price'
    values << json["details"]["sale_price"]
  end
  if !json["details"]["sale_price_currency"].nil?
    fields << 'sale_price_currency'
    values << json["details"]["sale_price_currency"]
  end
  if !json["details"]["sale_price_exchange_rate_to_dollars"].nil?
    fields << 'sale_price_exchange_rate_to_dollars'
    values << json["details"]["sale_price_exchange_rate_to_dollars"]
  end
  if !json["details"]["sale_price_dollars"].nil?
    fields << 'sale_price_dollars'
    values << json["details"]["sale_price_dollars"]
  end
  if !json["details"]["sale_price_sq_meter"].nil?
    fields << 'sale_price_sq_meter'
    values << json["details"]["sale_price_sq_meter"]
  end
  if !json["details"]["sale_price_sq_meter_dollars"].nil?
    fields << 'sale_price_sq_meter_dollars'
    values << json["details"]["sale_price_sq_meter_dollars"]
  end
  if !json["details"]["space"].nil?
    fields << 'space'
    values << json["details"]["space"]
  end
  if !json["details"]["space_measurement"].nil?
    fields << 'space_measurement'
    values << json["details"]["space_measurement"]
  end
  if !json["details"]["land"].nil?
    fields << 'land'
    values << json["details"]["land"]
  end
  if !json["details"]["land_measurement"].nil?
    fields << 'land_measurement'
    values << json["details"]["land_measurement"]
  end
  if !json["details"]["renovation"].nil?
    fields << 'renovation'
    values << json["details"]["renovation"]
  end
  if !json["details"]["view"].nil?
    fields << 'view'
    values << json["details"]["view"]
  end
  if !json["details"]["metro"].nil?
    fields << 'metro'
    values << json["details"]["metro"]
  end
  if !json["details"]["project"].nil?
    fields << 'project'
    values << json["details"]["project"]
  end
  if !json["details"]["condition"].nil?
    fields << 'place_condition'
    values << json["details"]["condition"]
  end
  if !json["details"]["function"].nil?
    fields << 'function'
    values << json["details"]["function"]
  end
  if !json["details"]["address"].nil?
    fields << 'address'
    values << json["details"]["address"]
  end
  if !json["details"]["address_city"].nil?
    fields << 'address_city'
    values << json["details"]["address_city"]
  end
  if !json["details"]["address_area"].nil?
    fields << 'address_area'
    values << json["details"]["address_area"]
  end
  if !json["details"]["address_district"].nil?
    fields << 'address_district'
    values << json["details"]["address_district"]
  end
  if !json["details"]["address_street"].nil?
    fields << 'address_street'
    values << json["details"]["address_street"]
  end
  if !json["details"]["address_number"].nil?
    fields << 'address_number'
    values << json["details"]["address_number"]
  end
  if !json["details"]["phone"].nil?
    fields << 'phone'
    values << json["details"]["phone"]
  end
  if !json["details"]["cadastral"].nil?
    fields << 'cadastral'
    values << json["details"]["cadastral"]
  end

  if !json["specs"]["all_floors"].nil?
    fields << 'all_floors'
    values << json["specs"]["all_floors"]
  end
  if !json["specs"]["floor"].nil?
    fields << 'floor'
    values << json["specs"]["floor"]
  end
  if !json["specs"]["rooms"].nil?
    fields << 'rooms'
    values << json["specs"]["rooms"]
  end
  if !json["specs"]["bedrooms"].nil?
    fields << 'bedrooms'
    values << json["specs"]["bedrooms"]
  end
  if !json["specs"]["conference_room"].nil?
    fields << 'conference_room'
    values << json["specs"]["conference_room"]
  end
  if !json["specs"]["suites"].nil?
    fields << 'suites'
    values << json["specs"]["suites"]
  end
  if !json["specs"]["wc"].nil?
    fields << 'wc'
    values << json["specs"]["wc"]
  end
  if !json["specs"]["bathroom"].nil?
    fields << 'bathroom'
    values << json["specs"]["bathroom"]
  end
  if !json["specs"]["shower"].nil?
    fields << 'shower'
    values << json["specs"]["shower"]
  end
  if !json["specs"]["fireplace"].nil?
    fields << 'fireplace'
    values << json["specs"]["fireplace"]
  end
  if !json["specs"]["air_conditioner"].nil?
    fields << 'air_conditioner'
    values << json["specs"]["air_conditioner"]
  end
  if !json["specs"]["balcony"].nil?
    fields << 'balcony'
    values << json["specs"]["balcony"]
  end
  if !json["specs"]["veranda"].nil?
    fields << 'veranda'
    values << json["specs"]["veranda"]
  end
  if !json["specs"]["loft"].nil?
    fields << 'loft'
    values << json["specs"]["loft"]
  end
  if !json["specs"]["bodrum"].nil?
    fields << 'bodrum'
    values << json["specs"]["bodrum"]
  end
  if !json["specs"]["mansard"].nil?
    fields << 'mansard'
    values << json["specs"]["mansard"]
  end
  if !json["specs"]["parking"].nil?
    fields << 'parking'
    values << json["specs"]["parking"]
  end
  if !json["specs"]["garage"].nil?
    fields << 'garage'
    values << json["specs"]["garage"]
  end
  if !json["specs"]["dist_from_tbilisi"].nil?
    fields << 'dist_from_tbilisi'
    values << json["specs"]["dist_from_tbilisi"]
  end
  if !json["specs"]["dist_from_cent_street"].nil?
    fields << 'dist_from_cent_street'
    values << json["specs"]["dist_from_cent_street"]
  end
  if !json["specs"]["box"].nil?
    fields << 'box'
    values << json["specs"]["box"]
  end
  if !json["specs"]["buildings"].nil?
    fields << 'buildings'
    values << json["specs"]["buildings"]
  end
  if !json["specs"]["administration_building"].nil?
    fields << 'administration_building'
    values << json["specs"]["administration_building"]
  end
  if !json["specs"]["workroom"].nil?
    fields << 'workroom'
    values << json["specs"]["workroom"]
  end
  if !json["specs"]["stockroom"].nil?
    fields << 'stockroom'
    values << json["specs"]["stockroom"]
  end
  if !json["specs"]["coefficient_k1"].nil?
    fields << 'coefficient_k1'
    values << json["specs"]["coefficient_k1"]
  end
  if !json["specs"]["coefficient_k2"].nil?
    fields << 'coefficient_k2'
    values << json["specs"]["coefficient_k2"]
  end

  if !fields.empty? && !values.empty?
    sql= "insert into postings("
    sql << fields.join(', ')
    sql << ") values("
    sql << values.map{|x| "\"#{mysql.escape(x.to_s)}\""}.join(', ')
    sql << ")"
  end

  return sql
end

# delete the record if it already exists
def delete_record_sql(mysql, posting_id, locale)
    sql = "delete from postings where posting_id = '"
    sql << mysql.escape(posting_id.to_s)
    sql << "' and locale = '"
    sql << mysql.escape(locale.to_s)
    sql << "'"

    return sql
end

# update github with any changes
def update_github
  unless environment_is_production
    puts 'NOT updating github because environment is not production'
    return false
  end

  puts 'pushing database to github'

  @log.info "------------------------------"
  @log.info "updating git"
  @log.info "------------------------------"
  x = Subexec.run "git add #{@db_dump_file} #{@status_file_name}"
  x = Subexec.run "git commit -m 'Updated database dump file and status.json with new makler.ge data'"
  x = Subexec.run "git push origin master"
end

def compress_file(file_path)
  file_name = File.basename(file_path)
  dir_path = File.dirname(file_path)

  compressed_file_path = "#{dir_path}/#{file_name}.zip"

  begin
    Zip::File.open(compressed_file_path, Zip::File::CREATE) do |zipfile|
      zipfile.add(file_name, file_path)
    end
  rescue StandardError => e
    @data_files_log.error "Could not zip #{file_path} ---> #{compressed_file_path}; error: #{e}"
  end

  File.delete(file_path)
end

def reached_max_num_ids_to_scrape
  !@max_num_ids_to_scrape.nil? && @num_ids_scraped >= @max_num_ids_to_scrape
end

def compress_data_files
  if uncompressed_data_files.empty?
    puts 'Data files are already compressed!'
    return
  end

  uncompressed_data_files.each do |file|
    compress_file(file)
  end
end

def uncompressed_data_files
  html_files = Dir.glob("#{@data_path}/**/*.html")
  json_files = Dir.glob("#{@data_path}/**/*.json")
  return html_files + json_files
end

def git_checkout_file(file)
  puts "Running 'git checkout -- #{file}'"
  `git checkout -- #{file}`
end
