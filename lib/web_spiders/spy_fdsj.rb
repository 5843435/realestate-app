module WebSpiders

  # bid (物件ID): 同一マンション名であっても部屋が異なるとBIDも異なる。
  #
  class SpyFdsj < Spy

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
        doc.css('table.result_all_part').each do |row|
          r = row.css('tr')
          #Rails.logger.info('table.result_all_part tr: %s' % r)

          detail_url = r[0].css('a')[0]['href']
          if detail_url.nil?
            Rails.logger.warn('detail_url is nil.')
            next
          end
          if detail_url[0] == "."
            detail_url = Settings.site_url.fdsj.base + "system" + detail_url.slice(1,detail_url.size)
          end

          bid = /bid=(\w+)/.match(detail_url)[1]
          if bid.nil?
            Rails.logger.warn('bid is nil.')
            next
          end

          name = r[0].css('a').text.strip
          price = r[1].css('td.imp').text.strip
          addr = r[2].css('p').text.strip
          trafic_info = r[3].css('p').text.strip
          occupied_area = r[4].css('td')[0].text.strip
          floor_plan = r[4].css('td')[1].text.strip
          built_at = r[5].css('td')[0].text.strip

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
        Realestate.create(records)
      end

      return true
    end

    private

    def visit_area_page
      # visit area page
      @web_sess.visit("http://www.fudousan.or.jp/system/?act=f&type=12&pref=%{area1}&stype=l" % { area1: @cond[:area1] } )
    end

    def crawl_area
      visit_area_page

      # tweaks area2 checkbox by its ids
      sleep(1)
      op_area2

      # set search conditions except area
      op_price_min
      sleep(1)
      op_price_max
      sleep(1)
      op_areasquare_min
      sleep(1)
      op_areasquare_max
      sleep(1)
      op_age_of_building
      sleep(1)
      op_minutes_to_take
      sleep(1)
      op_floor_plan

      # execute search request
      sleep(1)
      op_click_button

    end

    def op_area2
      return unless @cond[:area2]

      area2 = normalize_checkbox_cond(@cond[:area2])
      return unless area2

      @web_sess.within 'table.area' do
        area2.each do |a|
          @web_sess.check a
        end
      end
    end


    def op_price_min
      return unless @cond[:price_min]
      @web_sess.within 'table.kensaku' do
        @web_sess.select @cond[:price_min], from: 'pl'
      end
    end


    def op_price_max
      return unless @cond[:price_max]
      @web_sess.within 'table.kensaku' do
        @web_sess.select @cond[:price_max], from: 'ph'
      end
    end


    def op_areasquare_min
      return unless @cond[:areasquare_min]
      @web_sess.within 'table.kensaku' do
        @web_sess.select @cond[:areasquare_min], from: 'asl'
      end
    end


    def op_areasquare_max
      return unless @cond[:areasquare_max]

      @web_sess.within 'table.kensaku' do
        @web_sess.select @cond[:areasquare_max], from: 'ash'
      end
    end


    def op_age_of_building
      return unless @cond[:age_of_building]
      @web_sess.find('input[name="yc"][value="%s"]' % @cond[:age_of_building]).set(true)
    end

    def op_minutes_to_take
      return unless @cond[:minutes_to_take]
      @web_sess.find('input[name="th"][value="%s"]' % @cond[:minutes_to_take]).set(true)
    end

    def op_floor_plan
      return unless @cond[:floor_plan]
      fp = normalize_checkbox_cond(@cond[:floor_plan])
      return unless fp
      fp.each do |a|
        @web_sess.find('input[name="md[]"][value="%s"]' % a).set(true)
      end
    end

    def op_click_button
      @web_sess.execute_script("$('form').trigger('submit');")
    end

    def op_next_page()
      return false unless @web_sess.evaluate_script("$('a').filter(function(){return $(this).text() == '次へ＞'; })[0]")
      @web_sess.execute_script("$('a').filter(function(){return $(this).text() == '次へ＞'; })[0].click();")
      return true
    end

    def crawl_list
      # http://www.fudousan.or.jp/system/?act=l&type=12&pref=13&stype=l&city%5B%5D=13101&pl=l&ph=5&asl=l&ash=h&submitbtn=l
      # check current url

      # search result should exist
      if @web_sess.has_css?('div[id="result_all_no"]')
        raise EmptyResultError, @cond.to_s
      end

      # sort by new
      @web_sess.execute_script("sort('n');");
      sleep(10)

      @crawled_pages = []
      #url = URI.parse(@web_sess.current_url)
      max_pages = @cond[:max_list_pages] || DEFAULT_MAX_LIST_PAGES
      max_pages.times do |t|
        sleep(20)
        @crawled_pages << save_crawled_html(t, 'body')
        # check whether next link is present.
        break unless op_next_page
      end
    end

  end
end
