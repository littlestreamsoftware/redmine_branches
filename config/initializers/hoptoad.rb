require 'hoptoad_notifier'

HoptoadNotifier.configure do |config|
  config.api_key = {
    :project => ENV['HOPTOAD_PROJECT'],
    :tracker => 'Bug',
    :api_key => ENV['HOPTOAD_KEY']
  }.to_yaml

  config.host = 'projects.littlestreamsoftware.com'
  config.secure = true
end
