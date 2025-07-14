# frozen_string_literal: true

module NestedRecord::Macro
  extend ActiveSupport::Concern

  module ClassMethods
    def has_many_nested(name, **options, &block)
      NestedRecord::Setup::HasMany.new(self, name, **options, &block)
    end

    def has_one_nested(name, **options, &block)
      NestedRecord::Setup::HasOne.new(self, name, **options, &block)
    end

    def nested_accessors(from:, **options, &block)
      NestedRecord::NestedAccessorsSetup.new(self, from, **options, &block)
    end

    def monetize(name, currency: nil, **options)
      require_money_rails!

      attribute_name = name.to_s
      currency_name = options[:with] || :"#{attribute_name}_currency"

      # Define the money attribute with custom type
      attribute attribute_name, NestedRecord::Type::Monetize.new(currency: currency, **options)

      # Define currency attribute if not explicitly disabled
      unless options[:with] == false || has_attribute?(currency_name)
        attribute currency_name, :string, default: -> { currency&.to_s || Money.default_currency.to_s }
      end

      # Override the setter to handle currency updates
      define_method "#{attribute_name}=" do |value|
        super(value)
        if value.is_a?(Money) && respond_to?("#{currency_name}=")
          send("#{currency_name}=", value.currency.to_s)
        end
      end
    end

    private

    def require_money_rails!
      begin
        require 'money-rails'
        require 'money'
      rescue LoadError
        raise NestedRecord::ConfigurationError,
              "money-rails gem is required for monetize attributes. Add 'gem \"money-rails\"' to your Gemfile."
      end
    end
  end
end
