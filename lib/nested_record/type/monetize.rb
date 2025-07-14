# frozen_string_literal: true

class NestedRecord::Type
  class Monetize < ActiveModel::Type::Value
    include ActiveModel::Type::Helpers::Mutable

    def initialize(currency: nil, **options)
      @currency = currency
      @options = options
      super()
    end

    def cast(value)
      return value if value.is_a?(Money)
      return nil if value.nil? || value == ''

      if value.is_a?(Hash)
        amount = value['amount'] || value[:amount]
        currency = value['currency'] || value[:currency] || @currency || Money.default_currency
        return Money.new(amount, currency) if amount
      elsif value.respond_to?(:to_i)
        currency = @currency || Money.default_currency
        return Money.new(value.to_i, currency)
      end

      nil
    end

    def deserialize(value)
      return nil if value.nil?

      if value.is_a?(String)
        begin
          parsed = ActiveSupport::JSON.decode(value)
          return cast(parsed) if parsed.is_a?(Hash)
        rescue JSON::ParserError
          # Try to parse as integer string
          return cast(value.to_i) if value.match?(/\A\d+\z/)
        end
      end

      cast(value)
    end

    def serialize(value)
      return nil if value.nil?

      if value.is_a?(Money)
        return {
          amount: value.cents,
          currency: value.currency.to_s
        }.to_json
      end

      # If not a Money object, try to cast it first
      money_value = cast(value)
      if money_value
        {
          amount: money_value.cents,
          currency: money_value.currency.to_s
        }.to_json
      else
        nil
      end
    end

    def changed_in_place?(raw_old_value, new_value)
      old_value = deserialize(raw_old_value)
      old_value != new_value
    end

    private

    def money_available?
      defined?(Money)
    end
  end
end
