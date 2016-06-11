class MailJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
  	Rails.logger.info(args)
  end
end
