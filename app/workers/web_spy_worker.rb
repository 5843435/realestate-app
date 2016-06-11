class WebSpyWorker

  include Sidekiq::Worker

  sidekiq_options :retry => false

  def perform(cond, search_id)
    ::WebSpiders::Spy.build(cond, search_id).run
  end
end
