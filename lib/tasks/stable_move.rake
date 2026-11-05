# frozen_string_literal: true

# Moves saved scenarios and collections, with their engine scenarios, from the default version to a
# stable version while that version is hidden. Records and scenarios keep their ids. The ETM must be
# offline from step 2 to step 6. Example for 2027.01.
#
# Every task reads and writes DIR, /stable_move unless given, and refuses when it doesn't exist. On
# the servers it is /var/www/stable_move on the host, which each command below mounts there.
#
# Connect to both hosts as the ops user, also for the scp in step 4: the folder belongs to ops.
#
#   1. Prepare the folder and select what moves
#      On both hosts, create the folder once, owned by the ops user:
#      > sudo install -d -o ops /var/www/stable_move
#      On the production host, write the datasets and saved scenarios to
#      /var/www/stable_move/selection.yml. Its format is in StableMove::Selection in my-etm.
#
#   2. Plan, in my-etm (production host)
#      > cd /var/www/my-etm && sudo docker compose run --rm -v /var/www/stable_move:/stable_move \
#        web bundle exec rails 'stable_move:plan[2027.01]'
#      Writes plan.json and prints a summary of what moves and what is skipped.
#
#   3. Export, in the etengine of the default version (production host)
#      > cd /var/www/etengine && sudo docker compose run --rm -v /var/www/stable_move:/stable_move \
#        web bundle exec rails stable_move:export
#      Writes export.msgpack.gz and reports missing scenarios, area-code mismatches and missing files.
#
#   4. Copy the export to the stable host (from your machine)
#      > scp -3 <production>:/var/www/stable_move/export.msgpack.gz <stable>:/var/www/stable_move/
#
#   5. Import, in the etengine of the stable version (stable host)
#      > cd /var/www/etengine_2027_01
#      > sudo docker compose run --rm -v /var/www/stable_move:/stable_move \
#        web bundle exec rails stable_move:import
#      Replaces every scenario there with those in the file and sets their roles from MyETM.
#
#   6. Commit, in my-etm (production host)
#      > cd /var/www/my-etm && sudo docker compose run --rm -v /var/www/stable_move:/stable_move \
#        web bundle exec rails stable_move:commit
#      Binds the copies, deletes the stable version's test data and the saved scenarios whose
#      current scenario the engine lacks, then moves the records.
#      Logs each record to DIR/move_log.jsonl.
#
# Steps 1 to 3 change nothing, so on their own they are a "dry run".
#
# To undo step 6, in my-etm (SAVED_SCENARIOS and COLLECTIONS limit it to those ids). It moves the
# records back but doesn't bring back what step 6 deleted:
#      > cd /var/www/my-etm && sudo docker compose run --rm -v /var/www/stable_move:/stable_move \
#        web bundle exec rails 'stable_move:revert[2027.01]'
#
namespace :stable_move do
  stable_dir = lambda do
    dir = Pathname.new(ENV.fetch('DIR', '/stable_move'))
    dir.directory? ? dir : abort("#{dir} doesn't exist. Mount it with -v, or give another DIR")
  end

  desc 'Writes the scenarios of DIR/plan.json to DIR/export.msgpack.gz, with their related rows and ' \
       'attachment files. Reads only. Runs in the engine the scenarios move from'
  task export: :environment do
    dir = stable_dir.call
    plan = JSON.parse(dir.join('plan.json').read)
    path = dir.join('export.msgpack.gz')
    started = Time.current

    report = path.open('wb') { |io| StableMove::Export.new(plan, io).call }

    puts JSON.pretty_generate(report.merge(
      'file' => path.to_s,
      'mb' => (path.size / 1024.0 / 1024).round(1),
      'seconds' => (Time.current - started).round
    ))
  rescue StableMove::Error => e
    abort(e.message)
  end

  desc 'Replaces every scenario in this engine with those in DIR/export.msgpack.gz and sets their ' \
       'roles from MyETM. Runs in the engine the scenarios move to, while its version is hidden'
  task import: :environment do
    path = stable_dir.call.join('export.msgpack.gz')
    started = Time.current

    report = path.open('rb') { |io| StableMove::Import.new(io).call }

    puts JSON.pretty_generate(report.merge('seconds' => (Time.current - started).round))
  rescue StableMove::Error => e
    abort(e.message)
  end
end
