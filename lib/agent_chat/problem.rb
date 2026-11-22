module AgentChat
  class Problem
    attr_reader :code, :message, :details

    def initialize(code, message, **details)
      @code = code
      @message = message
      @details = details
    end

    def as_json
      { code: code.to_s, message:, **details }
    end
  end
end
