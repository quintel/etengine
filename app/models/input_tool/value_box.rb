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

    # Used to bind a ValueBox instance to a dataset yml.erb template.
    #
    def get_binding
      binding
    end

    # Sets a shortcut for a value. Typically used in conjunction with multiple #get.
    #
    #     set(:hh_demand_bln, (get(households, demand_total) / BILLIONS) )
    #         `··· key ····´   `··· value ····························´
    #
    def shortcut(key, value)
      @values[key] = value
    end
    alias_method :set, :shortcut

    # Recursively retrieves a value from the input tool value hashes.
    # 
    #     {:foo => {:bar => {:baz => 3.0 }}}
    #
    #     get(:foo) # => nil
    #     get(:foo, default : 23.0) # => 23.0
    #
    #     get(:foo, :bar, :baz) # => 3.0
    #     get(:foo, :bar, :baz, default : 23.0) # => 3.0
    #     
    #
    # @option args [Float] :default Value returned if lookup value is undefined or nil
    # @option args [Float] :error   Value returned if exception happens
    #
    def get(*args)
      options = args.extract_options!

      value = nil
      hsh = @values.with_indifferent_access
      # iterate with keys through nested hash.
      # only assign value a number after iterating over *all* keys.
      args.each do |key|
        if hsh.has_key?(key)
          hsh = hsh[key]
          if args.last == key
            value = hsh 
          else
            hsh = hsh.with_indifferent_access
          end
        end
      end
      value.nil? ? options[:default] : value.to_f
    rescue => e
      options[:error] || raise(e)
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