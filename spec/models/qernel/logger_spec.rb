require 'spec_helper'

module Qernel
  describe Logger do
    describe "to_tree" do
      it "should nest a tree" do
        logs = []
        logs << (l1  = { :nesting => 1, :id => 1  } )
        logs << (l21 = { :nesting => 2, :id => 11 } )
        logs << (l31 = { :nesting => 3, :id => 31 } )
        logs << (l32 = { :nesting => 3, :id => 121 } )
        logs << (l32 = { :nesting => 4, :id => 121 } )
        logs << (l32 = { :nesting => 2, :id => 21 } )

        tree = Logger.to_tree(logs)
        # 1 root element:
        expect(tree.length).to eq(1)
        expect(tree.first[0]).to eq({nesting: 1, id: 1})
        root = tree.first[1]
        # 2 childs for root
        expect(root.length).to eq(2)
        # the leafs of the 2 children:
        expect(root.values.first.length).to eq(2) # the two leafs with nesting 3( 31,121)
        expect(root.values.last).to eq(nil)
      end
    end
  end
end
