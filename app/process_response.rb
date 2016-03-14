require_relative 'environment'

def process_response(response, post_date)
  # pull out the locale and id from the url
  id = get_param_value(response.request.url, 'id')
  locale = get_param_value(response.request.url, 'lan')
  locale_key = get_locale_key(locale)

  if id.nil? || locale.nil? || locale_key.nil?
    @makler_log.error "response url is not in expected format: #{response.request.url}; expected url to have params of 'id' and 'lan'"
    return
  end

  # get the name of the folder for this id
  # - the name is the id minus it's last 3 digits
  id_folder = get_parent_id_folder(id)
  folder_path = @data_path + id_folder + "/" + id + "/" + post_date.strftime('%Y-%m-%d') + "/" + locale_key.to_s + "/"

  # get the response body
  doc = Nokogiri::HTML(response.body)

  if doc.css('td.table_content').length != 2
    @makler_log.error "the response does not have any content to process"
    return
  end

  # save the response body
  file_path = folder_path + @response_file
	create_directory(File.dirname(file_path))
  File.open(file_path, 'w'){|f| f.write(doc)}
  compress_file(file_path)

  # create the json
  json = json_template

  json[:posting_id] = id
  json[:locale] = locale_key.to_s

  # get the type/date
  header_row = doc.css('.div_for_content > .page_title')
  if header_row.length > 0
    span = header_row.css('span')
    if span.length == 0
      # the title is not correct so assume this is
      # not a page that can be processed.
      @status.remove_json_id(id, locale_key)

      @makler_log.warn "the id #{id} with language #{locale} does not have any data"

      return
    end
    type_text = span[0].xpath('text()').text.strip
    json[:type] = get_page_type(type_text, locale).to_s
    json[:property_type] = get_property_type(type_text, locale).to_s

    date = header_row.css('span')[header_row.css('span').length-1].xpath('text()').text.strip
    # need to convert from dd/mm/yyyy to yyyy-mm-dd
    json[:date] = Date.strptime(date, '%d.%m.%Y').strftime
  end

  # details info
  details_titles = doc.css('td.mc_title')
  details_values = doc.css('td.mc_title + td')
  if details_titles.length > 0 && details_values.length > 0
    details_titles.each_with_index do |title, title_index|
      title_text = title.text.strip.downcase
      # get the index for the key with this text
      index = @locales[locale_key][:keys][:details].values.index{|x| title_text == x}
      if index
        # get the key name for this text
        key = @locales[locale_key][:keys][:details].keys[index]

        # save the value
        json[:details][key] = details_values[title_index].text.strip

        if !json[:details][key].nil? && json[:details][key].length > 0
          # if this is a sale price, pull out the price and price per sq meter
          if @sale_keys.include?(key) && !@non_number_price_text.include?(json[:details][key])
            prices = json[:details][key].split('/')
            price_ary = prices[0].strip.split(' ')

            json[:details][:sale_price] = price_ary[0].strip
            json[:details][:sale_price_currency] = price_ary[1].strip if !price_ary[1].nil?

            # if price per sq meter present, save it
            if prices.length > 1
              json[:details][:sale_price_sq_meter] = prices[1].strip.split(' ')[0].strip
            end

            # if the currency is known, convert to dollars
            if !json[:details][:sale_price_currency].nil?
              currency_index = @currencies.keys.index(json[:details][:sale_price_currency].downcase)
              if !currency_index.nil?
                # exchange rate
                json[:details][:sale_price_exchange_rate_to_dollars] = @currencies.values[currency_index]

                # price
                if !json[:details][:sale_price].nil?
                  price = json[:details][:sale_price].to_f
                  json[:details][:sale_price_dollars] = price * @currencies.values[currency_index]
                end
                # price per sq meter
                if !json[:details][:sale_price_sq_meter].nil?
                  price = json[:details][:sale_price_sq_meter].to_f
                  json[:details][:sale_price_sq_meter_dollars] = price * @currencies.values[currency_index]
                end
              else
                @missing_param_log.error "Missing currency exchange #{json[:details][:sale_price_currency]} in record #{id}"
              end
            end


          # if this is a rent price, pull out the price and price per sq meter
          elsif @rent_keys.include?(key) && !@non_number_price_text.include?(json[:details][key])
            prices = json[:details][key].split('/')
            price_ary = prices[0].strip.split(' ')

            json[:details][:rent_price] = price_ary[0].strip
            json[:details][:rent_price_currency] = price_ary[1].strip if !price_ary[1].nil?

            # if price per sq meter present, save it
            if prices.length > 1
              json[:details][:rent_price_sq_meter] = prices[1].strip.split(' ')[0].strip
            end


            # if the currency is known, convert to dollars
            if !json[:details][:rent_price_currency].nil?
              currency_index = @currencies.keys.index(json[:details][:rent_price_currency].downcase)
              if !currency_index.nil?
                # exchange rate
                json[:details][:rent_price_exchange_rate_to_dollars] = @currencies.values[currency_index]

                # price
                if !json[:details][:rent_price].nil?
                  price = json[:details][:rent_price].to_f
                  json[:details][:rent_price_dollars] = price * @currencies.values[currency_index]
                end
                # price per sq meter
                if !json[:details][:rent_price_sq_meter].nil?
                  price = json[:details][:rent_price_sq_meter].to_f
                  json[:details][:rent_price_sq_meter_dollars] = price * @currencies.values[currency_index]
                end
              else
                @missing_param_log.error "Missing currency exchange #{json[:details][:sale_rent_currency]} in record #{id}"
              end
            end

          # if this is a square meter key, split the number and measurement
          elsif @sq_m_keys.include?(key)
            values = json[:details][key].split(' ')
            json[:details][key] = values[0].strip
            new_key = key.to_s + '_measurement'
            json[:details][new_key.to_sym] = values[1].strip if !values[1].nil?
          # if this is address, split it into its parts
          elsif @address_key == key
            address_parts = json[:details][key].split(',')
            if !address_parts[0].nil?
              json[:details][:address_city] = address_parts[0].strip
            end
            if !address_parts[1].nil?
              json[:details][:address_area] = address_parts[1].strip
            end
            if !address_parts[2].nil?
              json[:details][:address_district] = address_parts[2].strip
            end
            if !address_parts[3].nil?
              json[:details][:address_street] = address_parts[3].strip
            end
            if !address_parts[4].nil?
              json[:details][:address_number] = address_parts[4].strip
            end
          end
        end
      else
        @missing_param_log.error "Missing detail json key for text: '#{title_text}' in record #{id}"
      end
    end
  end

  # spec info
  specs_titles = doc.css('span.dc_title')
  specs_values = doc.css('span.dc_title + span')
  if specs_titles.length > 0 && specs_values.length > 0
    specs_titles.each_with_index do |title, title_index|
      title_text = title.text.strip.downcase
      # get the index for the key with this text
      index = @locales[locale_key][:keys][:specs].values.index{|x| title_text == x}
      if index
        # get the key name for this text
        key = @locales[locale_key][:keys][:specs].keys[index]
        # save the value
        json[:specs][key] = specs_values[title_index].text.strip
      else
        @missing_param_log.error "Missing spec json key for text: '#{title_text}' in record #{id}"
      end
    end
  end

  # additional info
  tables = nil
  if locale_key == :en
    tables = doc.css('table.fen')
  else
    tables = doc.css('table.fge')
  end
  if tables.length > 6
    tds = tables[5].css('td')
    if tds.length > 2
      # there may be many rows so grab them all
      # ignore first row for it is header
      tds.each_with_index do |td, index|
        # if this is not the additional info section, stop
        break if index == 0 && td.text.strip.downcase != @locales[locale_key][:keys][:additional_info]
        if index > 0
          text = td.text.strip
          if text != @nbsp
            if json[:additional_info].nil?
              json[:additional_info] = text
            else
              json[:additional_info] += " \n #{text}"
            end
          end
        end
      end
    end
  end

  if !json[:posting_id].nil?
    # save the json
    file_path = folder_path + @json_file
    create_directory(File.dirname(file_path))
    File.open(file_path, 'w'){|f| f.write(json.to_json)}
  end

  @status.remove_json_id(id, locale_key)
end
