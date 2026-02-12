require 'minitest/autorun'
require 'agent_chat'

class ServiceFactorySpec < Minitest::Test
  def test_should_raise_error_when_room_is_nil
    # Given/When/Then
    error = assert_raises(ArgumentError) do
      AgentChat::Service::Main.standard(room: nil)
    end

    assert_match(/room/i, error.message, "Error should mention room")
  end

  def test_should_raise_error_when_room_is_empty_string
    # Given/When/Then
    error = assert_raises(ArgumentError) do
      AgentChat::Service::Main.standard(room: "")
    end

    assert_match(/room/i, error.message, "Error should mention room")
  end

  def test_should_raise_error_when_room_is_whitespace_only
    # Given/When/Then
    error = assert_raises(ArgumentError) do
      AgentChat::Service::Main.standard(room: "   ")
    end

    assert_match(/room/i, error.message, "Error should mention room")
  end
end
