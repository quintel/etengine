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
        # logs << (l33 = { :nesting => 3, :id => 33 } )
        # logs << (l22 = { :nesting => 2, :id => 22 } )
        
        tree = Logger.to_tree(logs)
        # tree.length.should == 1
        # binding.pry
        # tree[l1][l21][l31].should == nil
        # tree[l1][l22].should == nil


      end
    end
  end
end
