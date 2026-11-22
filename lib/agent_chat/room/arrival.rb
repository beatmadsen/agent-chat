module AgentChat
  module Room
    Arrival = Data.define(:kind, :backup_path) do
      def self.existing = new(kind: :existing, backup_path: nil)
      def self.created = new(kind: :created, backup_path: nil)
      def self.reset(backup_path) = new(kind: :reset, backup_path:)
    end
  end
end
