module Qernel
  module DatasetCurveAttributes
    def dataset_curve_reader(name)
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}                                   # def availability_curve
          dataset_get(#{name.to_sym.inspect}) || []   #   dataset_get(:availability_curve) || []
        end                                           # end
      RUBY
    end

    def dataset_curve_writer(name)
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}=(value)                           # def availability_curve=(value)
          dataset_set(#{name.to_sym.inspect}, value)  #   dataset_set(:availability_curve, value)
        end                                           # end
      RUBY
    end

    def dataset_carrier_curve_reader(carrier)
      dataset_curve_reader("#{carrier}_input_curve")
      dataset_curve_reader("#{carrier}_output_curve")
    end

    def dataset_curve_accessor(name)
      dataset_curve_reader(name)
      dataset_curve_writer(name)
    end
  end
end
