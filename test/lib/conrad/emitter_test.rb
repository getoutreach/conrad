# frozen_string_literal: true

require 'test_helper'
require 'json'

class EmitterTest < Minitest::Test
  def test_inline_emission
    @emitter = GlobalEmitter.new
    @emitter.call('lol')
    assert_equal(['lol'], @emitter.events)
  end

  def test_background_emission
    @emitter = GlobalEmitter.new(background: true)
    assert_equal([], @emitter.events)
    @emitter.call('lol')
    assert_equal([], @emitter.events)
    sleep 0.2
    assert_equal(['lol'], @emitter.events)
  end
end
