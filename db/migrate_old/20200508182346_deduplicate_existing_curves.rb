class DeduplicateExistingCurves < ActiveRecord::Migration[5.2]
  def up
    unless ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)
      say 'Not de-duplicating curves as service is ' \
          "a #{ActiveStorage::Blob.service.class}"
      return
    end

    checksums = ActiveStorage::Blob.select(:checksum).distinct.pluck(:checksum)

    checksums.each do |checksum|
      deduplicate_checksum(checksum)
    end

    say_with_time 'Cleaning up empty ./storage/ directories' do
      cleanup_dirs
    end
  end

  def down
    ActiveRecord::IrreversibleMigration
  end

  private

  def deduplicate_checksum(checksum)
    blobs = ActiveStorage::Blob.where(checksum: checksum)

    return if blobs.length < 2

    say_with_time "De-duplicating curves with checksum #{checksum.inspect}" do
      canonical = nil

      blobs.each_with_index do |blob, index|
        if index.zero?
          canonical = blob
        else
          ActiveStorage::Attachment
            .where(blob_id: blob.id)
            .update_all(blob_id: canonical.id)

          blob.purge
        end
      end
    end
  end

  def cleanup_dirs
    children = Pathname.glob("#{ActiveStorage::Blob.service.root}/**/*")

    # Deepest paths first.
    children.sort_by! { |c| -c.to_s.split('/').length }

    children.each do |c|
      c.unlink if c.directory? && c.children.empty?
    end
  end
end
