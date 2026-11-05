# frozen_string_literal: true

# Moves saved scenarios and collections, with their engine scenarios, from the default version to a
# stable version while that version is hidden. Records and scenarios keep their ids.
#
# The steps:
#   1. Prepare the folder         DIR on both hosts, with selection.yml on the default version's host
#   2. Take production offline    not for a dry run
#   3. Plan                       stable_move:plan, in my-etm
#   4. Export                     stable_move:export, in the default version's etengine
#   5. Copy the export            export.msgpack.gz to DIR on the stable version's host
#   6. Import                     stable_move:import, in the stable version's etengine
#   7. Commit                     stable_move:commit, in my-etm
#   8. Bring production back online
# To undo step 7: stable_move:revert, in my-etm.
#
# A dry run is steps 1, 3 and 4 with production online: plan and export change nothing.
#
# Every task reads and writes DIR, /stable_move unless given, and refuses when it doesn't exist.
# The full procedure, with the commands for the servers, is in the stable version runbook.
namespace :stable_move do
  stable_dir = lambda do
    dir = Pathname.new(ENV.fetch('DIR', '/stable_move'))
    dir.directory? ? dir : abort("#{dir} doesn't exist. Mount it with -v, or give another DIR")
  end

  desc 'Writes the scenarios of DIR/plan.json to DIR/export.msgpack.gz, with their related rows and ' \
       'attachment files, and its report to DIR/export.json. Reads only. Runs in the engine the ' \
       'scenarios move from'
  task export: :environment do
    dir = stable_dir.call
    plan = JSON.parse(dir.join('plan.json').read)
    path = dir.join('export.msgpack.gz')
    started = Time.current

    report = path.open('wb') { |io| StableMove::Export.new(plan, io).call }
    dir.join('export.json').write(JSON.generate(report))

    puts JSON.pretty_generate(report.merge(
      'file' => path.to_s,
      'mb' => (path.size / 1024.0 / 1024).round(1),
      'seconds' => (Time.current - started).round
    ))
  rescue StableMove::Error => e
    abort(e.message)
  end

  desc 'Replaces every scenario in this engine with those in DIR/export.msgpack.gz. ' \
       'Refuses while a scenario here is newer than the export. ' \
       'Runs in the engine the scenarios move to'
  task import: :environment do
    path = stable_dir.call.join('export.msgpack.gz')
    started = Time.current

    report = path.open('rb') { |io| StableMove::Import.new(io).call }

    puts JSON.pretty_generate(report.merge('seconds' => (Time.current - started).round))
  rescue StableMove::Error => e
    abort(e.message)
  end
end
