# frozen_string_literal: true

module PadlockAuth
  class Config
    ##
    # PadlockAuth configuration option DSL.
    #
    # Adds configuration methods to a builder class which will be used to configure the object.
    #
    # Adds accessor methods to the object being configured.
    #
    # @example
    #  class MyConfig
    #    class Builder < PadlockAuth::Config::AbstractBuilder; end
    #
    #    mattr_reader(:builder_class) { Builder }
    #
    #    extend PadlockAuth::Config::Option
    #
    #    option :name
    #  end
    #
    #  config = MyConfig.builder_class.build do
    #    name 'My Name'
    #  end
    #  config.name # => 'My Name'
    #
    module Option
      # Defines configuration option
      #
      # When you call option, it defines two methods. One method will take place
      # in the +Config+ class and the other method will take place in the
      # +Builder+ class.
      #
      # The +name+ parameter will set both builder method and config attribute.
      # If the +:as+ option is defined, the builder method will be the specified
      # option while the config attribute will be the +name+ parameter.
      #
      # If you want to introduce another level of config DSL you can
      # define +builder_class+ parameter.
      # Builder should take a block as the initializer parameter and respond to function +build+
      # that returns the value of the config attribute.
      #
      # @param name [Symbol] The name of the configuration option
      # @param options [Hash] The options hash which can contain:
      #   - as [String] Set the builder method that goes inside +configure+ block
      #   - default [Object] The default value in case no option was set
      #   - builder_class [Class] Configuration option builder class
      #
      #
      # @example
      #   option :name
      #
      # @example
      #   option :name, as: :set_name
      #
      # @example
      #   option :name, default: 'My Name'
      #
      # @example
      #   option :scopes, builder_class: ScopesBuilder
      #
      #
      def option(name, options = {})
        attribute = options[:as] || name

        builder_class.instance_eval do
          if method_defined?(name)
            Kernel.warn "[PADLOCK_AUTH] Option #{self.name}##{name} already defined and will be overridden"
            remove_method name
          end

          define_method name do |*args, &block|
            if (deprecation_opts = options[:deprecated])
              warning = "[PADLOCK_AUTH] #{self.class.name}##{name} has been deprecated and will soon be removed"
              warning = "#{warning}\n#{deprecation_opts.fetch(:message)}" if deprecation_opts.is_a?(Hash)

              Kernel.warn(warning)
            end

            value = block || args.first

            config.instance_variable_set(:"@#{attribute}", value)
          end
        end

        define_method attribute do |*_args|
          if instance_variable_defined?(:"@#{attribute}")
            instance_variable_get(:"@#{attribute}")
          else
            options[:default]
          end
        end

        public attribute
      end

      # Uses extended hook to ensure builder_class is defined.
      #
      # Implementing classes should define a +builder_class+ method that returns a builder class.
      #
      def self.extended(base)
        return if base.respond_to?(:builder_class)

        raise NotImplementedError,
          "Define `self.builder_class` method for #{base} that returns your custom Builder class to use options DSL!"
      end
    end
  end
end
