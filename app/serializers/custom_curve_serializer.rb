# frozen_string_literal: true

# Provides JSON information about a custom curve.
class CustomCurveSerializer
  # @param user_curve [UserCurve] an object with a serialized curve and metadata.
  def initialize(user_curve)
    @user_curve = user_curve
    @curve = user_curve.curve
  end

  def as_json(*)
    return {} unless @user_curve.loadable_curve?

    data = UnattachedCustomCurveSerializer.new(config).as_json

    data.merge!(
      attached: true,
      name: @user_curve.name || @user_curve.key,
      size: serialized_size,
      date: @user_curve.created_at.utc,
      stats: stats
    )

    data
  end

  private

  def key
    @user_curve.key.chomp('_curve')
  end

  def config
    @config ||= CurveHandler::Config.find(@user_curve.key.chomp('_curve'))
  end

  def serialized_size
    @user_curve[:curve]&.bytesize || 0
  end

  def stats
    min_index = 0
    max_index = 0

    @curve.each_with_index do |value, index|
      max_index = index if value > @curve[max_index]
      min_index = index if value < @curve[min_index]
    end

    {
      length: @curve.length,
      min_at: min_index,
      max_at: max_index
    }
  end
end
