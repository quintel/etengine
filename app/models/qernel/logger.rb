module Qernel
  class Logger
    attr_accessor :nesting
    attr_reader :logs

    def initialize
      @nesting = 0
      @logs    = []
    end

    def increase_nesting
      @nesting += 1
    end

    def decrease_nesting
      @nesting -= 1
    end

    def push(attrs)
      attrs = attrs.merge(:nesting => @nesting)
      @logs.push attrs
      attrs
    end

    def log(type, key, attr_name, value = nil, options = nil)
      options ||= {}
      log = push({
        key:       key,
        attr_name: attr_name,
        value:     value,
        type:      type
      }.merge(options))
      if block_given?
        increase_nesting
        log[:value] = yield
        decrease_nesting
      end
      log[:value]
    end



    # Transforms the flat array into a nested hash tree by using the :nesting information.
    # The log level objects are always keys and the values being the subtree or nil if its
    # terminating.
    #
    # - root       (nesting: 1)
    # +- 1         (nesting: 2)
    #  +- 1.1      (nesting: 3)
    #  +- 1.2      (nesting: 3)
    #   + 1.2.1    (nesting: 4)
    # +- 2         (nesting: 2)
    #
    # =>
    #
    # { root: {
    #     1: {
    #       1.1: n
    #       1.2: {1.21: nil}
    #     }
    #     2: n
    #   }
    # }
    #
    def self.to_tree(subtree, include_root = true)
      return nil if subtree.empty?

      # Dirty hack. if there's more then one root element, add an
      # 'artificial' root element with nesting - 1. To remove the
      # hack, rewrite this method to allow for multiple root elements.
      nest = subtree.first[:nesting]
      if nest == 0 && subtree.rindex{|l| l[:nesting] == nest} > 0
        subtree.insert(0, {:nesting => nest - 1, :attr_name => 'root'})
      end

      first         = subtree.first
      child_nesting = first[:nesting] + 1
      children      = subtree.select{|l| l[:nesting] == child_nesting }

      hsh = {}

      children.each_with_index do |l, idx|
        next_child = children[idx+1]
        idx1   = subtree.index( l )
        idx2   = subtree.index( next_child ) || 0
        # The subtree are all elements from child l until the next child (with
        # same nesting). This spans a new subtree with l being the parent and the
        # logs inbetween as children.
        hsh[l] = to_tree(subtree[ idx1 .. idx2-1 ], false)
      end
      # Let's make outer leafs nil, instead of an empty hash
      # e.g. root[1][1.2][1.21] should be nil not {}
      hsh = nil if hsh.empty?

      if include_root
        {first => hsh}
      else
        hsh
      end
    end

    def to_hash
      logs.each_with_object({}) do |log, obj|
        obj[log[:key]] ||= {}
        obj[log[:key]].merge! log[:attr_name] => log[:value]
      end
    end
  end
end