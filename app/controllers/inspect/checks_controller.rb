class Inspect::ChecksController < Inspect::BaseController
  layout 'application'

  def loops
  end

  def expected_demand
  end

  # Shows the sum of the inputs in each share group.
  def index
  end

  def gquery_results
    @gqueries = Gquery.all.sort
  end

  #######
  private
  #######

  # A helper class for presenting and calculating share group information.
  class ShareGroup < Struct.new(:key, :gql)
    # @return [Array<Input>]
    #   Returns all of the inputs which belong to the group.
    def inputs
      @inputs ||= Input.in_share_group(key).reject do |input|
        input.disabled_in_current_area?(gql)
      end
    end

    # @return [true, false]
    #   Returns if the group sums up to -- or very close to -- 100.
    def ok?
      sum >= 99.9999 && sum <= 100.0001
    end

    # @return [BigDecimal]
    #   Returns the sum of all the input start values.
    def sum
      @sum ||= inputs.map { |input| input.start_value_for(gql) }.compact.sum
    end
  end

  # @return [Array<Inspect::ShareGroupsController::ShareGroup>]
  #   Returns a ShareGroup for each one defined in ETSource.
  def share_groups_for_area(area)
    gql    = Scenario.new(area_code: area, end_year: 2050).gql
    groups = Input.all.map(&:share_group)

    groups.reject!(&:blank?)
    groups.uniq!
    groups.sort!

    groups.map { |group| ShareGroup.new(group, gql) }
  end

  helper_method :share_groups_for_area
end
