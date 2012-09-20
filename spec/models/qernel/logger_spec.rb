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
        tree.length.should == 1
        tree.first[0].should == {nesting: 1, id: 1}
        root = tree.first[1]
        # 2 childs for root
        root.length.should == 2
        # the leafs of the 2 children:
        root.values.first.length.should == 2 # the two leafs with nesting 3( 31,121)
        root.values.last.should == nil
      end
    end
  end
end
