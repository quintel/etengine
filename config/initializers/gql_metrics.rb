# This initializer will catch the use of deprecated gqueries. Since there can be thousands of events
# we should decide what to do with them. At the moment I'm just showing them on the log. We could
# save them to a separate log file or store them externally and use a gquery counter.
#
ActiveSupport::Notifications.subscribe 'gql.deprecated' do |name, start, finish, id, payload|
  Rails.logger.debug "Deprecated Gquery: #{payload}"
end

ActiveSupport::Notifications.subscribe 'gql.prepare_present' do |name, start, finish, id, payload|
  Rails.logger.debug "Prepared present: (#{(finish - start) / 1000}ms)"
end

ActiveSupport::Notifications.subscribe 'gql.prepare_future' do |name, start, finish, id, payload|
  Rails.logger.debug "Prepared present: (#{(finish - start) / 1000}ms)"
end
