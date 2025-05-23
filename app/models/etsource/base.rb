module Etsource
  # Proxy to the git operations
  #
  class Base
    include Singleton

    attr_accessor :base_dir, :cache_topology, :export_dir

    def initialize
      @base_dir       = ETSOURCE_DIR
      @export_dir     = ETSOURCE_EXPORT_DIR
      @cache_topology = Settings.etsource_cache_topology
    end

    def self.loader(base_dir = nil)
      instance.base_dir   = base_dir if base_dir
      instance.export_dir = base_dir if base_dir
      Loader.instance
    end

    # Given a path as a string, returns the path as a Pathname. If the path is
    # not absolute, it is assumed to be relative to the Rails root, and an
    # absolute version is returned.
    #
    # Returns a Pathname.
    def self.clean_path(path)
      path.to_s[0] == '/' ? Pathname.new(path) : Rails.root.join(path)
    end

    # set to true to force reloading the topology
    def cache_topology?
      @cache_topology
    end

    # Public: Given a Git reference, returns the matching commit.
    #
    # Returns an Etsource::Commit
    def commit(ref)
      Commit.new(self, git.gcommit(ref))
    end

    def commits
      git.log(50).map { |gcommit| Commit.new(self, gcommit) }
    end

    def get_latest_export_sha
      import_sha_file
    end

    # Exports a revision. Git doesn't have a command similar to `svn export`, so this
    # emulates it. The revision passed as parameter will be exported to the
    # Settings.etsource_export_dir. The directory will first be deleted (to get rid
    # of stale files) unless you disable this in your config.yml.
    def export(sha_id)
      return false if Settings.etsource_disable_export

      if @export_dir.exist?
        @export_dir.children.each { |child| FileUtils.rm_rf(child) }
      else
        FileUtils.mkdir(@export_dir)
      end

      # Make 100% sure that the branch is placed back at the HEAD; it seems
      # other Git.open calls can cause Git commands belong to fail, citing that
      # the commits don't exist.
      commit  = commit(sha_id)
      archive = Rails.root.join('tmp').join("ets-#{ sha_id }.tar")

      commit.gcommit.archive(archive, format: 'tar')
      system("tar -x -C '#{ @export_dir }' -f '#{ archive }'")

      archive.delete

      update_latest_import_sha(sha_id)
    end

    def refresh
      git.fetch

      branches  = git.branches
      return_to = detached_branch? ? 'master' : current_branch

      branches.local.each do |branch|
        if branches["remotes/origin/#{ branch.to_s }"]
          git.checkout(branch)
          git.reset_hard("origin/#{ branch.to_s }")
        end
      end

      git.checkout(return_to)
    end

    # branch operations
    #
    def current_branch
      git.current_branch
    end

    def detached_branch?
      current_branch =~ /no branch/
    end

    def branches
      git.branches.local.map(&:name)
    end

    def checkout(branch)
      git.checkout branch
    end

    def update_latest_import_sha(sha)
      File.write(import_sha_file, "#{ sha }\n")
    end

    def get_latest_import_sha
      File.read(import_sha_file).strip
    rescue Errno::ENOENT
      nil
    end

    def last_updated_at(folder)
      if latest_import_sha = get_latest_import_sha
        git.gcommit(latest_import_sha)
          .log(1).object(folder).map(&:date).first
      end
    end

    private

    def import_sha_file
      "#{@export_dir}/REVISION"
    end

    def git
      @git ||= Git.open(@base_dir, repository: @base_dir.join('.git'))
    end
  end
end
