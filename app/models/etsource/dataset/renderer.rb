module Etsource
  # Renderer for datasets/_wizards/*/dataset.yml
  # Makes sure yaml files have binding and can access ValueBox.
  #
  # ------ Examples -------------------------------------------------------------
  # 
  #     value_box = InputTool::ValueBox.area('nl')
  #     renderer = Etsource::Dataset::Renderer.new(value_box, "etsource/datasets/_wizards/households/dataset.yml")
  #     renderer.result # => Hash 
  #
  #
  # ------ Binding to ETsource template -----------------------------------------
  #
  # A ETsource dataset yml file has a binding to the Etsource::Dataset object. Meaning 
  # that inside a yml file a method will have the Etsource::Dataset as scope.
  #
  #     ---
  #     heating: <%= get( 'foo', 'bar' ) %>
  #
  # Above yaml will call the Etsource::Dataset#get with 'foo' and 'bar' as arguments.
  # The binding happens in #load_yaml (if it has disappeared search for 'binding').
  #
  # ------ method_missing meta programming --------------------------------------
  #
  # @deprecated
  #
  # @updated I disabled this for now. Not critical to success and the research folks
  #  should have enough mental capabilities to prepend every string with a ":".
  #
  #
  # To make life easier for researchers I (sb) decided to let them omit the '' or
  # symbol : for the get arguments.
  #
  #     ---
  #     heating: <%= get('foo', 'bar') %>
  #     heating: <%= get(foo, bar) %>
  #
  # I argue that the second example is rather prettier and less prone to typo-bugs.
  # It works because the yaml file is bound to the value_box object, therefore foo
  # will trigger the ValueBox#method_missing and return :foo back.
  #
  class Dataset::Renderer
    attr_reader :country, :value_box, :file_path
    
    def initialize(value_box, file_path)
      @value_box = value_box
      @file_path = file_path
    end

    def result
      if has_research_data?
        load_yaml || {}
      else
        {}
      end      
    end

    # ----- Methods for within YAML -------------------------------------------

    # Access values from the static dataset.
    #
    # @param key [String,Symbol] a key of a converter,link or slot "heating_demand-(hot_water)"
    # @param attr_key [String,Symbol] the attribute name.
    #
    def val(key, attr_key)
      @dataset.data[group_key(key)][Hashpipe.hash(key)][attr_key.to_sym]
    end

    # @see {InputTool::ValueBox#get}
    #
    def get(*args)
      value_box.get(*args)
    end

    # @see {InputTool::ValueBox#set}
    #
    def shortcut(key, value)
      value_box.set(key, value)
    end
    alias_method :set, :shortcut

  protected
    
    # Returns true if we have research data for this file/form.
    # Do so by checking if the form_code matches the path (they have to).
    def has_research_data?
      value_box.form_codes.any?{|c| file_path.include?("/#{c}/") }
    end

    def group_key(key)
      key = key.to_s
      if key.include?('-->')  then :link
      elsif key.include?('(') then :slot
      else                         :converter; end
    end

    def load_yaml
      load_yaml_with_erb(File.read(file_path))
    end

    # ---- ERB MAGIC ----------------------------------------------------------
    # 
    # Run yaml contents through ERB renderer and attaches itself as a binding.
    #
    def load_yaml_with_erb(str)
      YAML::load(ERB.new(str).result(  binding  ))
    end
  end
end