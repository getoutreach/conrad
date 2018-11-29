$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'outreach_auditor'

require 'minitest/autorun'
require 'minitest/pride'

class OutreachAuditorTestCase < Minitest::Test
  make_my_diffs_pretty!
end
