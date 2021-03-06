$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'specjour'
require 'spec/autorun'

class NullObject
  def method_missing(name, *args)
    self
  end
end

begin
  Specjour::DbScrub
rescue LoadError
  $stderr.puts "DbScrub failed to load properly, that's okay though"
end

Spec::Runner.configure do |config|
  config.mock_with :rr
end
