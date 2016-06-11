class WebSpyJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
  	WebSpiders::Spy.build(args).run
  end

end
