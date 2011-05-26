module LayoutHelper
  
  def title(str)
    haml_tag :h2, str
  end

  # TODO move controller_name logic to Tab
  def tab(title, controller_name = title, action_name = nil)
    class_name = (controller.controller_name == controller_name) ? 'active' : nil
    if action_name.nil?
      link = "/#{controller_name}"
    else
      link = (controller_name == "") ? '/' : "/#{controller_name}/#{action_name}"
    end
    haml_tag :li, :class => class_name, :id => title.downcase do
      haml_tag :a, I18n.t(title.capitalize), :href => link
    end
  end

end
