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
namespace :stable_move do
  stable_dir = lambda do
    dir = Pathname.new(ENV.fetch('DIR', '/stable_move'))
    dir.directory? ? dir : abort("#{dir} doesn't exist. Mount it with -v, or give another DIR")
  end
  show = ->(lines) { puts '-' * 72, lines, '-' * 72 }
  stop = ->(error) { abort(['-' * 72, "Stopped: #{error.message}", '-' * 72].join("\n")) }

  # Shows a summary and goes on only when the person running the task types yes. Without a terminal
  # there is no answer, so it stops.
  confirm = lambda do |lines, question|
    show.call(lines)
    print("#{question} Type yes to proceed: ")
    $stdout.flush
    abort('Stopped: nothing was changed') unless $stdin.gets&.strip == 'yes'
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

    show.call([
      "Wrote #{path} in #{(Time.current - started).round} seconds: " \
      "#{(path.size / 1024.0 / 1024).round(1)} MB",
      "Wrote the report for the commit to #{dir.join('export.json')}",
      *StableMove::Export.summary(report)
    ])
  rescue StableMove::Error => e
    stop.call(e)
  end

  desc 'Replaces every scenario in this engine with those in DIR/export.msgpack.gz. Shows what it ' \
       'will delete and asks to confirm. Refuses while a scenario here is newer than the export. ' \
       'Runs in the engine the scenarios move to'
  task import: :environment do
    path = stable_dir.call.join('export.msgpack.gz')
    preview = path.open('rb') { |io| StableMove::Import.new(io).preview }

    confirm.call(preview, "Replace every scenario in #{Settings.version_tag} with those in the file?")

    started = Time.current
    report = path.open('rb') { |io| StableMove::Import.new(io).call }

    show.call(["Imported in #{(Time.current - started).round} seconds", '', *report])
  rescue StableMove::Error => e
    stop.call(e)
  end
end
