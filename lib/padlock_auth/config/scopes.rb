# frozen_string_literal: true

module PadlockAuth
  class Config
    # Represents a collection of scopes.
    #
    class Scopes
      include Enumerable
      include Comparable

      # Create a new Scopes instance from a string.
      #
      # @param string [String] A space-separated string of scopes
      #
      # @return [PadlockAuth::Config::Scopes] A new Scopes instance
      def self.from_string(string)
        string ||= ""
        new.tap do |scope|
          scope.add(*string.split(/\s+/))
        end
      end

      # Create a new Scopes instance from an array.
      #
      # @param array [Array<String>] An array of scopes
      #
      # @return [PadlockAuth::Config::Scopes] A new Scopes instance
      #
      def self.from_array(*array)
        new.tap do |scope|
          scope.add(*array)
        end
      end

      delegate :each, :empty?, to: :@scopes

      # Initialize a new Scopes instance.
      def initialize
        @scopes = []
      end

      # Check if a scope exists in the collection.
      #
      # @param scope [String] The scope to check
      #
      # @return [Boolean] True if the scope exists
      #
      def exists?(scope)
        @scopes.include? scope.to_s
      end

      # Add a scope to the collection.
      #
      # @param scopes [Array<String>] The scopes to add
      #
      def add(*scopes)
        @scopes.push(*scopes.flatten.compact.map(&:to_s))
        @scopes.uniq!
      end

      # Returns all scopes in the collection.
      #
      # @return [Array<String>] All scopes
      def all
        @scopes
      end

      # Returns all scopes as a string.
      #
      # @return [String] All scopes as a space-joined string
      def to_s
        @scopes.join(" ")
      end

      # Returns true if all scopes exist in the collection.
      #
      # @param scopes [Array<String>] The scopes to check
      #
      # @return [Boolean] True if all scopes exist
      def scopes?(scopes)
        scopes.all? { |scope| exists?(scope) }
      end

      alias_method :has_scopes?, :scopes?

      # Adds two collections of scopes together.
      #
      def +(other)
        self.class.from_array(all + to_array(other))
      end

      # Compares two collections of scopes.
      #
      # @param other [PadlockAuth::Config::Scopes, Array<String>] The other collection
      #
      def <=>(other)
        if other.respond_to?(:map)
          map(&:to_s).sort <=> other.map(&:to_s).sort
        else
          super
        end
      end

      # Returns a scopes array with elements contained in both collections.
      #
      # @param other [PadlockAuth::Config::Scopes, Array<String>] The other collection
      #
      def &(other)
        self.class.from_array(all & to_array(other))
      end

      private

      def to_array(other)
        case other
        when Scopes
          other.all
        else
          other.to_a
        end
      end
    end
  end
end
