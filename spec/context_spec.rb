# spec/context_spec.rb
require_relative '../cop.rb'

class C
  def foo; 1; end
  def bar; 2; end
end


describe Context do

  context '#reset_cop_state' do
    context 'when two context c1 c2 are created and activated on the method foo of klass C' do
      before(:each) do
        @c1 = Context.new
        @c1.adapt(C,:foo){10}
        @c1.activate
        @c2 = Context.new
        @c2.adapt(C,:foo){20}
        @c2.activate
        Context.reset_cop_state
      end

      it 'foo must return 1' do
        expect(C.new.foo).to eq 1
      end

    end
  end

end