module AgentChat
  module GlobalId
    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'.freeze
    LENGTH = 7

    def self.generate(random = Random)
      Array.new(LENGTH) { ALPHABET[random.rand(ALPHABET.length)] }.join
    end
  end
end
