require 'capybara/poltergeist'

module WebSpiders

  class EmptyResultError < StandardError; end

  class Spy
    attr_reader :cond, :web_sess, :crawled_pages, :search_id

    DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.86 Safari/537.36"

    def self.build(cond, search_id=nil)
      cond.deep_symbolize_keys!

      # validate condition hash
      valid, err = Cond.new(cond).check
      raise 'invalid a codition hash has been specified: %s' % err unless valid
      klass_name = 'spy_' + cond[:site_slug]
      klass_name = 'WebSpiders::' + klass_name.classify

      # overwrite search_id unless search_id is nil.
      if search_id.nil?
        search_id = Time.now.strftime('%Y%m%d%H%M%S').to_i
      end

      Object.const_get(klass_name).new(cond, search_id)
    end

    def initialize(cond, search_id)
      @cond = cond
      @search_id = search_id
      @ua = DEFAULT_USER_AGENT
      init_driver
    end

    def init_driver
      Capybara.register_driver :poltergeist_debug do |app|
        Capybara::Poltergeist::Driver.new(app, :inspector => true)
      end

      #Capybara.javascript_driver = :poltergeist
      Capybara.javascript_driver = :poltergeist_debug
      @web_sess = Capybara::Session.new(:poltergeist)
      @web_sess.driver.headers = { 'User-Agent' => @ua }
    end

    def logger_info(v)
      Rails.logger.info('[%s] %s' % [self.to_s, v])
    end

    def logger_error(v, e)
      Rails.logger.info('[%s] %s with error: %s' % [self.to_s, v, e.inspect])
    end

    def run
      logger_info('---- run spider')
      begin
        crawl
        scrape
        logger_info('---- succeeded spider')
        notify_success
      rescue => e
        logger_error('---- failed spider', e)
        notify_error(e)
      end
    end

    def crawl
      raise 'Unsupported method has been called.'
    end

    def scrape
      raise 'Unsupported method has been called.'
    end

    def notify_success
      ResultMailer.notify_success(@search_id).deliver_now
    end

    def notify_error(error)
      ResultMailer.notify_error(error).deliver_now
    end

    def create_csv
    end

    def remove_csv
    end

    def save_crawled_html(num, outer_sel)
      fpath = Rails.root.join('tmp/spiders/%s/html/' % @cond[:site_slug])
      FileUtils.mkdir_p(fpath)
      fpath = fpath.join('%s.html' % num)
      FileUtils.touch(fpath)
      open(fpath, 'w') do |f|
        html = '<!DOCTYPE html><html lang="ja"><head><meta charset="UTF-8"><title>Document</title></head><body>%s</body></html>'
        f << html % @web_sess.evaluate_script('$("%s").html();' % outer_sel)
      end
    end

    def op_select(select_name, v)
      return unless v
      @web_sess.select v, from: select_name
    end

    def op_unselect(select_name, unselect = false)
      @web_sess.unselect from :select_name
    end

    def op_checkbox(sel, val, b = true)
      val = [val] unless val.is_a?(Array)
      val.each do |v|
        @web_sess.find(sel % v).set(b)
      end
    end

    def op_radio(sel, val, b = true)
      return unless val
      @web_sess.find(sel % val).set(b)
    end

    def op_click(sel)
      @web_sess.execute_script(sel + ".trigger('click')")
    end

    def normalize_checkbox_cond(cond)
      cond.split(',')
    end
  end
end
