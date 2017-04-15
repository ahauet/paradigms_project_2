require 'rspec/autorun'
require_relative '../extra.rb'

describe Context do
  context '#active?' do
    context 'when the context is created' do
      before {
        reset_cop_state
        @c = Context.new
      }
      it 'returns false' do
        expect(@c.active?).to eq false
      end
    end
  end

  context '#activate' do
    context 'when there are no context created' do
      before {
        reset_cop_state
        @c = Context.new
      }
      it 'does not affect the counter of the context' do
        expect(@c.count).to eq 0
      end
      context 'when the context is activate' do
        before {
          @c.activate
        }
        it 'increments the counter of the context' do
          expect(@c.count).to eq 1
        end
        context 'when the context is deactivate' do
          before {
            @c.deactivate
          }
          it 'decreases the counter of the context' do
            expect(@c.count).to eq 0
          end
        end
      end
    end
    context 'when a context is activate and it is activate two times' do
      before{
        reset_cop_state
        @c = Context.new
        @c.activate
        @c.activate
      }
      it 'increments two times the counter of the context' do
        expect(@c.count).to eq 2
      end
    end
    context 'when a context c1 is created, has an adaptation on method foo of klass C and activated' do
      before {
        reset_cop_state
        class C
          def foo
            1
          end
          def bar
            2
          end
        end
        @c1 = Context.new
        @c1.adapt(C,:foo){42}
        @c1.activate
      }
      it 'modifies the method foo of klass C' do
        expect(C.new.foo).to eq 42
      end
      context 'when c1 is activate again and an other context c2 is created,  has an adaptation on method foo of klass C and activated' do
        before {
          @c1.activate
          @c2 = Context.new
          @c2.adapt(C,:foo){84}
          @c2.activate
        }
        it 'modifies the method foo of klass C' do
          expect(C.new.foo).to eq 42
        end
        context 'when c2 is activated two times more' do
          before {
            @c2.activate
            @c2.activate
          }
          it 'modifies the method foo of klass C' do
            expect(C.new.foo).to eq 84
          end
        end
      end
    end
  end

  context '#deactivate' do
    context 'when'
  end
end

describe ContextManager do
  context '#get_current_context' do
    context 'when there are no context created' do
      before {
        reset_cop_state
      }
      it 'returns nil' do
        expect(ContextManager.instance.get_current_context).to eq nil
      end
    end
    context 'when a context is created and activated' do
      before {
        reset_cop_state
        @c1 = Context.new
        @c1.activate
      }
      it 'returns the context c1' do
        expect(ContextManager.instance.get_current_context).to eq @c1
      end
    end
    context 'when two contexts are created and the first is activate one time and the second two times' do
      before {
        reset_cop_state
        @c1 = Context.new
        @c1.activate
        @c2 = Context.new
        @c2.activate
        @c2.activate
      }
      it 'returns the context c2' do
        expect(ContextManager.instance.get_current_context).to eq @c2
      end
    end
  end
end