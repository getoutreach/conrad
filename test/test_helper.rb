$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'conrad'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/stub_const'

class ConradTestCase < Minitest::Test
  make_my_diffs_pretty!
end

class GlobalEmitter < Conrad::Emitters::Base
  attr_reader :events

  def setup(*)
    @events = []
  end

  def emit(event)
    sleep 0.1
    @events << event
  end
end
