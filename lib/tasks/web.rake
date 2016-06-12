namespace :web do

    desc "web crawling and scraping task"

    # $ rake web:spy
    task :spy => :environment do
      #search_id = Time.now.strftime('%Y%m%d%H%M%S').to_i
      search_id = nil

      # Retrieve a condition info from settings for FDJS and YAHJ
      conds = YAML.load_file(Rails.root.join('config', 'search_conds.yml'))

      conds.each do |c|
        #WebSpyJob.perform_later(c) # Eventually queue adapter is determined with sidekiq only without active job.
        WebSpyWorker.perform_async(c, search_id)
        sleep(3)
      end
    end

    desc "conditions hash validation"

    task :check_conds => :environment do
      conds = YAML.load_file(Rails.root.join('config', 'search_conds.yml'))
      conds.each do |c|
        c = Cond.new(c)
        valid, err = c.check
        if valid
          puts "OK: " + c.attributes.to_s
        else
          puts "ERROR: " + err + ", attributes: " + c.attributes.to_s
        end
      end
    end

    desc "check application environtmen and settings at once."

    task :check_env => :environment do
        puts Rails.env
        puts Realestate.count()
    end
end
