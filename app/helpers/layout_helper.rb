module LayoutHelper
  def title(str)
    haml_tag :h2, str
  end
end
