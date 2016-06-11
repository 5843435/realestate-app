module WebSpiders

  # bid (物件ID): 同一マンション名であっても部屋が異なるとBIDも異なる。
  #
  class SpyYahf < Spy

    DEFAULT_MAX_LIST_PAGES = 5

    def crawl
      # crawring between area page and list page in which describing realestates
      crawl_area
      crawl_list
    end

    def scrape
      # scraping crawled pages
      return false if @crawled_pages.compact.empty?

      site_slug = @cond[:site_slug]
      searched_at = Time.now
      records = []
      cond = Cond.new(@cond)

      @crawled_pages.each do |p|
        doc = File.open(p) { |f| Nokogiri::HTML(f) }
        doc.css('li.usedListBoxWrap').each do |row|

          name = row.css('p.usedListBoxTit > span').first.text.strip
          dd = row.css('dl.usedListBoxDate > dd')
          addr = dd[0].text.strip
          trafic_info = dd[1].text.strip
          built_at = dd[2].text.strip

          tr = row.css('table.usedListBoxDate2 tr')
          tr.slice(1,tr.length).each do |t|
            # exclude tr.log_info
            next if t['class'] == "log_info"

            td = t.css('td')
            floor_plan = td[3].css('.imgPop > a')
            unless floor_plan
              floor_plan = td[3].css('.imgPop > span')
            end
            floor_plan = floor_plan.text.strip
            occupied_area = td[4].text.strip
            price = td[5].text.strip
            detail_url = td[7].css('a').first[:href]
            bid = /detail_\w+\/(\w+)?\//.match(detail_url)[1]

            rs = Realestate.where(bid: bid).first
            if rs.nil?
              rs = Realestate.where(name: name, price: price, addr: addr, trafic_info: trafic_info, occupied_area: occupied_area, floor_plan: floor_plan, built_at: built_at).sort(searched_at: -1).first
            end

            if rs.nil?
              records << {
                search_id: @search_id,
                searched_at: searched_at,
                site_slug: site_slug,
                name: name,
                detail_url: detail_url,
                bid: bid,
                price: price,
                addr: addr,
                trafic_info: trafic_info,
                occupied_area: occupied_area,
                floor_plan: floor_plan,
                built_at: built_at,
                search_cond: cond.to_humanize
              }
            end
          end
        end
        Realestate.create(records)
      end

      return true
    end

    private

    def visit_area_page
      @web_sess.visit("http://realestate.yahoo.co.jp/used/mansion/03/%{area1}/" % { area1: @cond[:area1] } )
    end

    def crawl_area
      visit_area_page

      # tweaks area2 checkbox by its ids
      op_area2

      # set search conditions except area
      op_price_min
      op_price_max
      op_areasquare_min
      op_areasquare_max
      op_age_of_building
      op_minutes_to_take
      op_floor_plan

      # execute search request
      op_click_button
    end

    def op_area2
      return unless @cond[:area2]

      area2 = normalize_checkbox_cond(@cond[:area2])
      return unless area2

      area2.each do |a|
        @web_sess.find('input[name="geo"][value="%s"]' % a).set(true)
      end
    end

    def op_price_min
      return unless @cond[:price_min]
      @web_sess.first('select[name=p_from]').find('option[value="%s"]' % @cond[:price_min]).select_option
      #@web_sess.select @cond[:price_min], :from => 'p_from' #=> Capybara::ElementNotFound: Unable to find option "10000000"
    end

    def op_price_max
      return unless @cond[:price_max]
      @web_sess.first('select[name=p_to]').find('option[value="%s"]' % @cond[:price_max]).select_option
      #@web_sess.select @cond[:price_max], from: 'p_to'
    end


    def op_areasquare_min
      return unless @cond[:areasquare_min]
      @web_sess.select @cond[:areasquare_min], from: 'ma_from'
    end


    def op_areasquare_max
      return unless @cond[:areasquare_max]
      @web_sess.select @cond[:areasquare_max], from: 'ma_to'
    end

    def op_age_of_building
      return unless @cond[:age_of_building]
      @web_sess.first('select[name=age]').find('option[value="%s"]' % @cond[:age_of_building]).select_option
      #@web_sess.select @cond[:age_of_building], from: 'age'
    end

    def op_minutes_to_take
      return unless @cond[:minutes_to_take]
      @web_sess.find('input[name="min_st"][value="%s"]' % @cond[:minutes_to_take]).set(true)
    end

    def op_floor_plan
      return unless @cond[:floor_plan]
      fp = normalize_checkbox_cond(@cond[:floor_plan])
      return unless fp

      fp.each do |a|
        @web_sess.find('input[name="rl_dtl"][value="%s"]' % a).set(true)
      end
    end

    def op_click_button
      # check total number of result
      if @web_sess.first('em.totalOfNumber').text.to_i <= 0
        raise EmptyResultError, @cond.to_s
      end

      # trigger click button
      @web_sess.execute_script("$('input[type=button][value=この条件で探す]').trigger('click');")
    end

    def op_next_page()
      return false unless @web_sess.has_css?('a#nextSearch')
      @web_sess.execute_script("$('a#nextSearch').trigger('click');")
      return true
    end

    def crawl_list
      # http://realestate.yahoo.co.jp/used/mansion/search/03/13/?p_to=20000000&geo=13220
      # check current url

      # result should exists
      #if @web_sess.find('div[id=result_all_no]')
      #  raise EmptyResultError, @cond.to_s
      #end

      # sort by new
      @web_sess.execute_script("$('select#sort').val('-info_open min_st p_from -area -rl -age').trigger('change');")
      sleep(5)

      @crawled_pages = []
      #url = URI.parse(@web_sess.current_url)
      max_pages = @cond[:max_list_pages] || DEFAULT_MAX_LIST_PAGES
      max_pages.times do |t|
        sleep(20)
        @crawled_pages << save_crawled_html(t, 'div#est_list')
        # check whether next link is present.
        break unless op_next_page
      end
    end
  end
end
