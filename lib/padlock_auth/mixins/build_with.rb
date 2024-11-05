module PadlockAuth
  module Mixins
    # Provides a quick way to build configuration instances.
    #
    # Provide `PadlockAuth::Utils::AbstractBuilder` sub-class to the `build_with` class method,
    # to define a build method that will take a block to configure the instance.
    #
    # @example
    #   class MyConfig
    #     include PadlockAuth::Mixins::BuildWith
    #
    #     class Builder < PadlockAuth::Utils::AbstractBuilder
    #       def name(value)
    #         config.instance_variable_set(:@name, value)
    #       end
    #     end
    #
    #     build_with Builder
    #   end
    #
    #   config = MyConfig.build do
    #     name 'My Name'
    #   end
    #   config.name # => 'My Name'
    #
    module BuildWith
      extend ActiveSupport::Concern

      included do
        # Prevent direct instantiation of the class
        private_class_method :new
      end

      class_methods do
        # Define a builder class for the configuration.
        #
        # The builder class should accept a call to `new` with a new instance of the
        # configuration class, and a block to configure the instance.
        #
        # @yield block to configure the builder class
        #
        def build_with(builder_class)
          mattr_reader(:builder_class) { builder_class }
          define_singleton_method(:build) { |&block| builder_class.new(new, &block).build }
        end
      end
    end
  end
end
