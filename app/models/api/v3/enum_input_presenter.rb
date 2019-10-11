module Api
  module V3
    class EnumInputPresenter < InputPresenter
      def as_json(*)
        attrs = super

        attrs[:permitted_values] = attrs.delete(:min)
        attrs.delete(:max)
        attrs.delete(:step)

        attrs
      end
    end
  end
end
