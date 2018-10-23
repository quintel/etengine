module Qernel
  module DatasetCurveAttributes
    def dataset_curve_reader(name)
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
          dataset_get(#{name.to_sym.inspect}) || []
        end
      RUBY
    end

    def dataset_carrier_curve_reader(carrier)
      dataset_curve_reader("#{carrier}_input_curve")
      dataset_curve_reader("#{carrier}_output_curve")
    end
  end
end
