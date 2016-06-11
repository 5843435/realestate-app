kill -USR1 `cat tmp/pids/sidekiq.pid`
kill -QUIT `cat tmp/pids/sidekiq.pid`
bundle exec sidekiq -vd

