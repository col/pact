module Pact
  module RSpec

    def self.color_enabled?
      if ::RSpec.configuration.respond_to?(:color_enabled?)
        ::RSpec.configuration.color_enabled?(::RSpec.configuration.output_stream)
      else
        ::RSpec.configuration.color_enabled?
      end
    end

    def self.full_description example
      example.respond_to?(:full_description) ? example.full_description : example.example.full_description
    end

    def self.runner_defined?
      defined?(::RSpec::Core::Runner)
    end
  end
end