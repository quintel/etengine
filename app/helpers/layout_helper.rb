module LayoutHelper
  def title(str)
    concat content_tag(:h2, str)
  end
end
