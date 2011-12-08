# ValueBox holds all the values entered by researchers into the input tool.
# They can be accessed systematically by ETsource templates using "get".
#
#     get(households,hot_water,demand) # => 32.0
#
# gets are meant to be chained togeter.
#
#     # Transform a percentage (50%) into a factor (0.5)
#     get(households,hot_water,share,heating) / 100 
#
# To DRY up ETsource templates we can also create shortcuts or macros using "set".
#
#     # Transform a percentage (50%) into a factor (0.5)
#     set(hh_hot_water_heating_share, get(households,hot_water,share,heating) / 100)
#     get(hh_hot_water_heating_share)
#  
#
# ------ Binding to ETsource template -----------------------------------------
#
# A ETsource dataset yml file has a binding to a value box object. This means 
# that inside a yml file calling any method will have the value box as scope.
#
#     ---
#     heating: <%= get( 'foo', 'bar' ) %>
#
# Above yaml will call the ValueBox#get with 'foo' and 'bar' as arguments to the 
# bound value box instance.
# The binding happens in Etsource::Datasets#load_yaml (if it has disappeared search
# for 'get_binding').
#
# ------ method_missing meta programming --------------------------------------
#
# To make life easier for researchers I (sb) decided to let them omit the '' or
# symbol : for the get arguments.
#
#     ---
#     heating: <%= get('foo', 'bar') %>
#     heating: <%= get(foo, bar) %>
#
# I argue that the second example is rather prettier and less prone to type-bugs.
# It works because the yaml file is bound to the value_box object, therefore foo
# will trigger the ValueBox#method_missing and return :foo back.
# 
#
module InputTool
  class ValueBox
    
    def initialize(forms)
      @values = forms.inject({}) {|hsh,f| hsh.merge f.code => f.dataset_values}
    end

    def self.area(code)
      new(InputTool::Form.where(:area_code => code).all)
    end

    def get_binding
      binding
    end

    def set(key, value)
      @values[key] = value
    end

    def get(*args)
      options = args.extract_options!

      value = nil
      args.each do |key|
        value ||= @values
        value = value.with_indifferent_access[key]
      end
      value.to_f
    rescue
      options[:default]
    end

    # This is used to simplify the use in ETsource. So that researchers do not have
    # to escape keys with '', or symbolize them.
    #
    #     get(households,hot_water,demand)
    #
    # See documentation section Binding above.
    #
    def method_missing(method, *args)
      method
    end
  end
end