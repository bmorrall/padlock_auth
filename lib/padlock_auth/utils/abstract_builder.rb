# frozen_string_literal: true

module PadlockAuth
  module Utils
    # Abstract base class for implementing configuration builders.
    #
    # Define a `validate!` method on the configuration instance to validate the configuration.
    #
    # @abstract
    #
    # @example
    #   class MyConfig
    #     class Builder < PadlockAuth::Utils::AbstractBuilder
    #       def name(value)
    #         config.instance_variable_set(:@name, value)
    #       end
    #     end
    #
    #     def self.build(&block)
    #       Builder.new(self, &block).build
    #     end
    #
    #     attr_reader :name
    #   end
    #
    #   config = MyConfig.build do
    #     name 'My Name'
    #   end
    #
    class AbstractBuilder
      # @return [Object] the instance being configured
      attr_reader :config

      # @param [Class] config instance
      #
      # @yield block to configure the instance
      #
      def initialize(config, &)
        @config = config
        instance_eval(&) if block_given?
      end

      # Builds and validates configuration.
      #
      # Invokes `validate!` on the configuration instance if it responds to it.
      #
      # @return [Object] the config instance
      #
      def build
        @config.validate! if @config.respond_to?(:validate!)
        @config
      end
    end
  end
end
