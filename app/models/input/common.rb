class Input
  module Common
    extend ActiveSupport::Concern

    included do
      include InMemoryRecord
      include CommandAttributes
      include ActiveModel::Validations

      extend ActiveModel::Naming

      attr_accessor :file_path
    end

    def initialize(attrs={})
      attrs && attrs.each do |name, value|
        send("#{name}=", value) if respond_to? name.to_sym
      end
    end

    def key=(new_key)
      new_key && (@key = new_key.to_s)
    end

    module ClassMethods
      def load_records
        Hash[inputs.map do |input|
          [input.key.to_s, input]
        end]
      end
    end

    # Public: The GQL::Command which represents the string held in the +query+
    # attribute.
    def command
      @command ||= command_for(:query)
    end
  end
end
