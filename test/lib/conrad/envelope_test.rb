require 'test_helper'

class EnvelopeTest < Minitest::Test
  def test_raises_type_error_for_non_array_envelope_keys
    assert_raises(TypeError) do
      Conrad::Processors::Envelope.new(payload_key: 'blah')
    end

    assert_raises(TypeError) do
      Conrad::Processors::Envelope.new(:foobar, payload_key: 'blah')
    end

    assert_raises(TypeError) do
      Conrad::Processors::Envelope.new({}, payload_key: 'blah')
    end
  end

  def test_wraps_payload_in_envelope_keys
    envelope = Conrad::Processors::Envelope.new(%i[foobar])
    event = { foobar: 'barrel', value: 'other', third: 'third' }

    assert_equal(
      { foobar: 'barrel', payload: { value: 'other', third: 'third' } },
      envelope.call(event)
    )
  end

  def test_always_includes_envelope_keys_if_missing_from_original_event
    envelope = Conrad::Processors::Envelope.new(%i[foobar fizzbazz])
    event = { fizzbazz: 'fizz', value: 'other', third: 'third' }

    assert_equal(
      { foobar: nil, fizzbazz: 'fizz', payload: { value: 'other', third: 'third' } },
      envelope.call(event)
    )
  end

  def test_uses_payload_as_default_payload_key
    envelope = Conrad::Processors::Envelope.new(%i[foobar])
    event = { foobar: 'barrel', value: 'other', third: 'third' }

    assert_equal(
      { foobar: 'barrel', payload: { value: 'other', third: 'third' } },
      envelope.call(event)
    )
  end

  def test_uses_given_payload_key_when_provided
    envelope = Conrad::Processors::Envelope.new(%i[foobar], payload_key: :extra)
    event = { foobar: 'barrel', value: 'other', third: 'third' }

    assert_equal(
      { foobar: 'barrel', extra: { value: 'other', third: 'third' } },
      envelope.call(event)
    )
  end
end
