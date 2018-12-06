$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'conrad'

require 'minitest/autorun'
require 'minitest/pride'

class ConradTestCase < Minitest::Test
  make_my_diffs_pretty!
end
