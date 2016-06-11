Sidekiq.configure_server do |config|
  Rails.logger = Sidekiq::Logging.logger
  config.redis = { url: 'redis://:GaiPhoh7iesee0dieng4Booh@localhost:6379', namespace: 'sidekiq' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://:GaiPhoh7iesee0dieng4Booh@localhost:6379', namespace: 'sidekiq' }
end
