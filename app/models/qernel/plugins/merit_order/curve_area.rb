module Qernel::Plugins
  module MeritOrder
    # Given a line with x,y coordinates, PolygonArea will calculate
    # the area below that line from a x_1 to x_2.
    #
    #     The polgyon area               What's the area?
    #
    #     |__                            |__
    #     |  --                          |  --
    #     |     -----                    |   |x-----
    #     |          ______              |   |xxxxx| ______
    #     |                ---           |   |xxxxx|       ---
    #     +-------------------           +-------------------
    #                                       lft   rgt
    #
    # The algorithm is inspired from http://alienryderflex.com/polygon_area/
    # points have to be passed in "around the clock" direction
    #
    # @example
    #
    #   poly = LdcPolygonArea.new()
    #   poly.area( converter ) # => ...
    #
    class CurveArea
      attr_reader :points, :x_max

      # points    - An array of [x,y] coordinates for the line
      # x_max     - the maximum y
      def initialize(points)
        @points = points
        @x_max  = points.last.first
      end

      # Area below the curve, from x1 to x2.
      #
      #
      #
      def area(x_lft, x_rgt)
        coordinates = coordinates(x_lft, x_rgt)
        polygon_area(coordinates.map(&:first), coordinates.map(&:second))
      end

      #######
      private
      #######

      # returns x,y coordinates of the polygon_area in clock-wise order.
      #
      # @example: coordinates(2,7)
      #
      #     *
      #   5 |  o
      #   3 |      o
      #   1 |         o
      #     +--o------o--*
      #        2   5  7  10
      #
      # => [2,0], [2,5], [5,3], [7,1], [7,0]
      #
      def coordinates(x_lft, x_rgt)
        [
          [x_lft, 0],                                     # bottom left
          [x_lft, interpolate_y(x_lft)],                  # top left (y interpolated)
          *points.select{|x,y| x > x_lft && x < x_rgt },  # points on residual_ldc curve
          [x_rgt, interpolate_y(x_rgt)],                  # top right (y interpolated)
          [x_rgt, 0]                                      # bottom right
        ]
      end


      # it interpolates the y value for a given x.
      #
      #
      # It uses the formulas i've learned at school and wikipedia
      def interpolate_y(x)
        return points.first.last if x == 0.0
        return 0.0 if x >= x_max

        index = points.index{|px,y| px >= x } - 1
        index = 0 if index < 0

        x1,y1 = points[index]
        x2,y2 = points[index + 1]

        m = (y2 - y1) / (x2 - x1)
        n = y1 - ((y2 - y1)/(x2-x1)) * x1

        y = m*x + n

        y.rescue_nan
      end

      # The actual algorithm from http://alienryderflex.com/polygon_area/
      def polygon_area(x_arr, y_arr)
        points = x_arr.length
        i = points - 1
        j = points - 1

        area = 0.0
        0.upto(points - 1) do |i|
          area += (x_arr[j] + x_arr[i])*(y_arr[j] - y_arr[i])
          j = i
        end
        area * 0.5
      end
    end # LdcCurveArea
  end # MeritOrder
end


