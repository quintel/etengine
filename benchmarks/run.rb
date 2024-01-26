# frozen_string_literal: true

load 'benchmarks/config/env.rb'

## Uncomment line below to turn off logging info messages to STDOUT.
# logger.level = :error

##
# The profiler used by default is StackProf. This proved to be the most
# stable and fast profiler tested. Currently RubyProf is also available
# as a profiler, however, it is not guaranteed this profiler can run
# and finish all profiling threads.
#
# To use it, change below to:
#   $profiler = Profiler::RubyProf.new
#
profiler = Benchmarks::Profiler::StackProf.new

###
# Benchmarks (or rather: profiling) can be initiated from the command-line as follows:
#   ruby benchmarks/run.rb <arguments>
#
# Possible arguments are:
#   -s/--scenario: Runs benchmarks for an existing scenario.
#     Accepts the following options:
#       ids: the id(s) of the scenario(s) to benchmark. May be a string of ids, seperated by a comma (but not spaces).
#            The scenario with the given id should be present in your development db ('etengine_development').
#
#     Example:
#       ruby benchmarks/run.rb --scenario 1045172
#       ruby benchmarks/run.rb -s 1045172,1045173,1045174
#
#   -i/--inputs: Runs benchmarks that simulate setting inputs on a new, empty scenario.
#     Accepts the following options:
#       -i/--individually:
#         Runs benchmarks where one individual input is set per request. Does this for all inputs.
#       -is/--individually-short:
#         Same as above, but takes one random input per slide.
#       -c/--combined:
#         Runs benchmarks where groups of 5, 10, 20 and 50 inputs are set per request.
#       -cs/--combined-per-sector:
#         Same as above, but does this for inputs related to the sectors:
#         households, agriculture and industry
#
#     Examples:
#       To benchmark setting value for one input:
#         ruby benchmarks/run.rb -i -i
#       To benchmark setting a number of inputs at once, grouped per sector:
#         ruby benchmarks/run.rb --inputs --combined-per-sector
#
case ARGV[0]
when '-s', '--scenario'
  Benchmarks::Runner::Scenario.new(profiler:, scenario_ids: ARGV[1]).run

when '-i', '--inputs'
  Benchmarks::Runner::Input.new(profiler:).run(type: ARGV[1])

end
