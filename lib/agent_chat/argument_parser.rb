module AgentChat
  class ArgumentParser
    FLAGS = [:room, :author, :consumer]

    def self.parse(args)
      return { action: :help } if args.empty? || args.include?('--help') || args.include?('-h')
      return { action: :version } if args.include?('--version') || args.include?('-v')

      flags = FLAGS.map { |flag| [flag, extract_flag(args, "--#{flag}")] }.to_h.compact
      { action: args[0].to_sym }.merge(flags)
    end

    def self.extract_flag(args, flag)
      index = args.index(flag)
      index ? args[index + 1] : nil
    end

    private_class_method :extract_flag
  end
end
