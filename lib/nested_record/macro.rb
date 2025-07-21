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

    def monetize(*fields)
      # Extract options the same way money-rails does
      options = fields.extract_options!

      # If this is being called with multiple fields (money-rails style)
      # or if this class has database columns (ActiveRecord), delegate to money-rails
      if fields.length > 1 || (respond_to?(:column_names) && respond_to?(:columns_hash))
        require_money_rails!
        # Reconstruct the original arguments for money-rails
        return super(*fields, options) if defined?(super)
      end

      # Handle NestedRecord monetize (single field, ActiveModel attributes)
      name = fields.first
      currency = options.delete(:currency)
      default = options.delete(:default)

      require_money_rails!

      attribute_name = name.to_s
      currency_name = options[:with] || :"#{attribute_name}_currency"

      # Define the money attribute with custom type
      attribute_options = {}
      attribute_options[:default] = -> { default } if default
      
      attribute attribute_name, NestedRecord::Type::Monetize.new(currency: currency, currency_attribute: currency_name, default: default, **options), **attribute_options

      # Define currency attribute if not explicitly disabled
      unless options[:with] == false || (respond_to?(:has_attribute?) && has_attribute?(currency_name))
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
