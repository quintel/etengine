# This initializer will catch the use of deprecated gqueries. Since there can be thousands of events
# we should decide what to do with them. At the moment I'm just showing them on the log. We could
# save them to a separate log file or store them externally and use a gquery counter.
#
GqlLogger = Logger.new(Rails.root.join('log/gql.log'))

ActiveSupport::Notifications.subscribe 'gql.gquery.deprecated' do |name, start, finish, id, payload|
  GqlLogger.info "gql.gquery.deprecated: #{payload}"
end

ActiveSupport::Notifications.subscribe 'gql.debug' do |name, start, finish, id, payload|
  GqlLogger.debug "gql.debug: #{payload}"
end

# Show all 'performance' related outputs
ActiveSupport::Notifications.subscribe /\.performance/ do |name, start, finish, id, payload|
  GqlLogger.debug "#{name}: (#{(finish - start)}ms)"
end

ActiveSupport::Notifications.subscribe /gql\.query/ do |name, start, finish, id, payload|
  GqlLogger.debug "#{name}: (#{(finish - start)}ms)"
end

ActiveSupport::Notifications.subscribe /gql\.inputs/ do |name, start, finish, id, payload|
  GqlLogger.debug "#{name}: #{payload}"
end

