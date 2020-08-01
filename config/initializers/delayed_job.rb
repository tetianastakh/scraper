TMIN = 0.1
TMAX = 0.25
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
Delayed::Worker.sleep_delay = rand(TMIN..TMAX)
