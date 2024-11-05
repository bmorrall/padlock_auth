module PadlockAuth
  module Mixins
    # Hide an attribute from inspection and JSON serialization.
    #
    # Prevents accidental exposure of sensitive data in logs or responses.
    #
    module HideAttribute
      extend ActiveSupport::Concern

      class_methods do
        # Hide an attribute from inspection and JSON serialization.
        #
        # @param attribute [Symbol, String] The attribute to hide
        #
        def hide_attribute(attribute)
          mod = Module.new
          mod.define_method(:inspect) do
            super().gsub(instance_variable_get(:"@#{attribute}"), "[REDACTED]")
          end
          mod.define_method(:as_json) do |options = nil|
            options ||= {}
            options[:except] ||= []
            options[:except] |= [attribute.to_s]
            super(options)
          end
          include mod
        end
      end
    end
  end
end
