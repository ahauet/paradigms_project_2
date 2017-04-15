# magic_ball_spec.rb
require "minitest/autorun"
require "minitest/spec"
require_relative "cop"

describe Context do
  describe "#active?" do
    it "new context never activate => activate?  returns false" do
      reset_cop_state
      context = Context.new
      refute context.active?
    end

    it "context adapt but never activate  => activate?  returns false" do
      reset_cop_state
      context = Context.new
      klass = Class.new
      context.adapt(klass,:foo) {"foo"}
      refute context.active?
    end

    it "context activate after adapt  => activate?  returns true" do
      reset_cop_state
      context = Context.new
      klass = Class.new
      context.adapt(klass,:foo) {"foo"}
      context.activate
      assert context.active?
    end

    it "deactivate new context" do
      reset_cop_state
      context = Context.new
      context.deactivate
      refute context.active?
    end

    it "activate deactivate context" do
      reset_cop_state
      context = Context.new
      context.activate
      context.deactivate
      refute context.active?
    end

    it "2 times activate deactivate context" do
      reset_cop_state
      context = Context.new
      context.activate
      context.activate
      context.deactivate
      refute context.active?
    end

    it "activate 2 times deactivate context" do
      reset_cop_state
      context = Context.new
      context.activate
      context.deactivate
      context.deactivate
      refute context.active?
    end

    it "interleaving activate deactivate context" do
      reset_cop_state
      context = Context.new
      context.activate
      context.deactivate
      context.activate
      context.deactivate
      refute context.active?
    end
  end

  describe ".reset_cop_state" do
    it "test reset class without method foo" do
      reset_cop_state
      klass = Class.new
      context = Context.new
      context.adapt(klass,:foo) {"foo"}
      context.activate
      reset_cop_state
      refute klass.instance_methods(false).include?(:foo)
    end

    it "test reset class without method foo" do
      reset_cop_state
      klass = Class.new
      context = Context.new
      context.adapt(klass,:foo) {"foo"}
      context.activate
      reset_cop_state
      refute klass.instance_methods(false).include?(:foo)
    end

    it "test reset class with initial method foo check existence" do
      reset_cop_state
      class Klass
        def foo
          "foo"
        end
      end
      context = Context.new
      context.adapt(Klass,:foo) {"foo1"}
      context.activate
      reset_cop_state
      assert Klass.instance_methods(false).include?(:foo)
      assert_equal "foo", Klass.new.foo
    end

    it "test reset class with initial method foo check implementation but 2 adapt" do
      reset_cop_state
      class Klass
        def foo
          "foo"
        end
      end
      context1 = Context.new
      context1.adapt(Klass,:foo) {"foo1"}
      context1.activate
      context2 = Context.new
      context2.adapt(Klass,:foo) {"foo2"}
      context2.activate
      reset_cop_state
      assert_equal "foo", Klass.new.foo
    end

    it "test reset class without initial method foo check implementation but 2 adapt" do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.adapt(klass,:foo) {"foo1"}
      context1.activate
      context2 = Context.new
      context2.adapt(klass,:foo) {"foo2"}
      context2.activate
      reset_cop_state
      refute_respond_to klass.new, :foo
    end

    it "test reset class with initial method foo after (activate/deactivate) context check implementation" do
      reset_cop_state
      class Klass
        def foo
          "foo"
        end
      end
      context = Context.new
      context.adapt(Klass,:foo) {"foo"}
      context.activate
      context.deactivate
      reset_cop_state
      assert_equal "foo", Klass.new.foo
    end

    it "test reset class with initial method foo check implementation multi-context" do
      reset_cop_state
      class Klass
        def foo
          "foo"
        end
      end
      context1 = Context.new
      context1.adapt(Klass,:foo) {"foo1"}
      context1.activate

      context2 = Context.new
      context2.adapt(Klass,:foo) {"foo2"}
      context2.activate

      reset_cop_state
      assert_respond_to Klass.new, :foo
      assert_equal "foo", Klass.new.foo
    end
  end
  describe "#adapt" do
    it "class without method adpat foo method " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.adapt(klass,:foo) {"foo"}
      context1.activate
      assert_equal "foo", klass.new.foo
    end

    it "class with initial foo method adpat foo method " do
      reset_cop_state
      class Klass
        def foo
          "foo"
        end
      end
      context1 = Context.new
      context1.adapt(Klass,:foo) {"foo1"}
      context1.activate
      assert_equal "foo1", Klass.new.foo
    end

    it "class without method adpat foo method 2 times " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.adapt(klass,:foo) {"foo1"}
      context1.activate
      context2 = Context.new
      context2.adapt(klass,:foo) {"foo2"}
      context2.activate
      assert_equal "foo2", klass.new.foo
    end

    it "class Klass adpat existing foo method and no existing method bar same context " do
      reset_cop_state
      class Klass
        def foo
          "foo"
        end
      end
      context1 = Context.new
      context1.adapt(Klass,:foo) {"foo1"}
      context1.adapt(Klass,:bar) {"bar1"}
      context1.activate

      assert_equal "foo1", Klass.new.foo
      assert_equal "bar1", Klass.new.bar
    end

    it "class Klass adpat form inactivate context " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.adapt(klass,:foo) {"foo1"}
      refute_respond_to klass.new, :foo
    end

    it "class Klass adpat one parameter method " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.adapt(klass,:pr) {|mot| "#{mot}"}
      context1.activate
      assert_equal "hello", klass.new.pr("hello")
    end

    it "class whitout initial method adapt then activate then adapt second
    context but de adaptations list of the default context must be empty  " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context2 = Context.new
      context1.adapt(klass,:foo) {"foo1"}
      context1.activate
      context2.adapt(klass,:foo) {"foo2"}
      assert_equal "foo1", klass.new.foo
    end


    it "class adapt after activate " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.activate
      context1.adapt(klass,:foo) {"foo1"}
      assert_equal "foo1", klass.new.foo
    end

    it "class 2 times adapt on same context " do
      reset_cop_state
      klass = Class.new
      context1 = Context.new
      context1.activate
      context1.adapt(klass,:foo) {"adapt1"}
      context1.adapt(klass,:foo) {"adapt2"}
      assert_equal "adapt2", klass.new.foo
    end
  end

  describe "#unadapt" do
    it "unadapt on inactivate context after adapt" do
      klass = Class.new
      context1 = Context.new
      context1.adapt(klass,:foo) {"adapt1"}
      context1.unadapt(klass,:foo)
      assert_empty context1.adaptations
    end

    it "unadapt a new context" do
      klass = Class.new
      context1 = Context.new
      context1.unadapt(klass,:foo)
      assert_empty context1.adaptations
    end

    it "unadapt a new context" do
      class Klass
        def foo
          "foo"
        end
      end
      context1 = Context.new
      context1.unadapt(Klass,:foo)
      assert_empty context1.adaptations
    end

    it "unadapt a inexistance class" do
      context1 = Context.new
      context1.unadapt(:klass,:foo)
      assert_empty context1.adaptations
    end

    it "unadapt a inexistance method" do
      klass = Class.new
      context1 = Context.new
      context1.unadapt(:klass,:foo)
      assert_empty context1.adaptations
    end

    it "unadapt on fly" do
      klass = Class.new
      context1 = Context.new
      context2 = Context.new
      context1.activate
      context1.adapt(klass,:foo) {"adapt1"}
      context2.activate
      context2.adapt(klass,:foo) {"adapt2"}
      context2.unadapt(klass,:foo)
      assert_equal "adapt1", klass.new.foo
    end
  end
end