# frozen_string_literal: true

require 'byebug'
require 'rubygems'
require 'ruby-prof'
require 'stackprof'

load 'config/environment.rb'

load 'benchmarks/profilers/base.rb'
load 'benchmarks/profilers/ruby_prof.rb'
load 'benchmarks/profilers/stackprof.rb'

load 'benchmarks/runners/base.rb'
load 'benchmarks/runners/input.rb'
load 'benchmarks/runners/scenario.rb'

load 'benchmarks/utils/input.rb'
load 'benchmarks/utils/scenario.rb'
