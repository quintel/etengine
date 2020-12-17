class EnumInputSerializer < InputSerializer
  def as_json(*)
    attrs = super

    attrs[:permitted_values] = attrs.delete(:min)
    attrs.delete(:max)
    attrs.delete(:step)

    attrs
  end
end
