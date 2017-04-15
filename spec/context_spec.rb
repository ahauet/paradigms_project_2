# spec/context_spec.rb
require_relative '../cop.rb'

class C
  def foo; 1; end
  def bar; 2; end
end

class D
  def add(x)
    x+1
  end
end

class E
end

describe Context do
  # context '#reset_cop_state' do
  #   context 'when a context is created, adapted and activated' do
  #     before {
  #       @c = Context.new
  #       @c.adapt(C,:foo){bar}
  #       @c.activate
  #       reset_cop_state
  #     }
  #     it 'resets cop state' do
  #       expect(C.new.foo).to eq 1
  #       expect(C.new.bar).to eq 2
  #     end
  #   end
  #   context 'when a context is created on a empty klass' do
  #     before {
  #       @c = Context.new
  #       @c.adapt(E, :foo){42}
  #       @c.activate
  #       reset_cop_state
  #     }
  #     it 'add the implementation of foo in add' do
  #       expect(E.instance_methods.grep(:foo).length).to eq 0
  #     end
  #   end
  # end
  # context '#active?' do
  #   context 'when a context is created and has an adaptation on the method foo of klass C' do
  #     before {
  #       reset_cop_state
  #       @c1 = Context.new
  #       @c1.adapt(C,:foo){bar}
  #     }
  #     context 'when the context is not activate' do
  #       it 'returns false' do
  #         expect(@c1.active?).to eq false
  #       end
  #     end
  #     context 'when the context is activate' do
  #       before {
  #         @c1.activate
  #       }
  #       it 'returns true' do
  #         expect(@c1.active?).to eq true
  #       end
  #       context 'when the context id deactivate' do
  #         before {
  #           @c1.deactivate
  #         }
  #         it 'returns false' do
  #           expect(@c1.active?).to eq false
  #         end
  #       end
  #     end
  #   end
  # end
  # context '#adapt' do
  #   before {
  #     reset_cop_state
  #     @c2 = Context.new
  #   }
  #   context 'when a adaptation to the method foo is added to the context' do
  #     before {
  #       @c2.adapt(C, :foo){20}
  #     }
  #     # Specific test
  #     it 'adds an adaptation to the context' do
  #       expect(@c2.adaptations.length).to eq 1
  #     end
  #     context 'when a adaptation to the method bar is added to the context' do
  #       before {
  #         @c2.adapt(C, :bar){10}
  #       }
  #       # Specific test
  #       it 'adds an adaptation to the context' do
  #         expect(@c2.adaptations.length).to eq 2
  #       end
  #     end
  #   end
  #   context 'when two context c4 and c5 are created and they adapt both the method foo of klass C' do
  #     before {
  #       reset_cop_state
  #       @c4 = Context.new
  #       @c4.adapt(C, :foo){40}
  #       @c5 = Context.new
  #       @c5.adapt(C, :foo){50}
  #     }
  #     context 'when context c4 is activate' do
  #       before {
  #         @c4.activate
  #       }
  #       it 'changes the implementation of foo' do
  #         expect(C.new.foo).to eq 40
  #       end
  #       context 'when context c5 is activate' do
  #         before {
  #           @c5.activate
  #         }
  #         it 'changes the implementation of foo' do
  #           expect(C.new.foo).to eq 50
  #         end
  #         context 'when context c4 is activate again' do
  #           before {
  #             @c4.activate
  #           }
  #           it 'changes the implementation of foo' do
  #             expect(C.new.foo).to eq 40
  #           end
  #           context 'when context c4 c5 are deactivate' do
  #             before {
  #               @c4.deactivate
  #               @c5.deactivate
  #             }
  #             it 'resets the implementation of foo' do
  #               expect(C.new.foo).to eq 1
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end
  #   context 'when a context is activate' do
  #     before {
  #       reset_cop_state
  #       @c4 = Context.new
  #       @c4.activate
  #       @c4.adapt(C, :foo){40}
  #     }
  #
  #     it 'modifies the implementation of foo' do
  #       expect(C.new.foo).to eq 40
  #     end
  #   end
  # end
  context '#activate' do
    # context 'when a context c is created and has an adaptation to the method foo' do
    #   before {
    #     reset_cop_state
    #     @c3 = Context.new
    #     @c3.adapt(C, :foo){10}
    #     @c3.activate
    #   }
    #
    #   context 'when the context is activate' do
    #     it 'modifies the implementation of the method foo in klass C' do
    #       expect(C.new.foo).to eq 10
    #     end
    #   end
    # end
    # context 'when a context c8 is created and has an adaptation on the method add of D' do
    #   before {
    #     reset_cop_state
    #     @c8 = Context.new
    #     @c8.adapt(D, :add){|x| x + 20}
    #   }
    #   context 'when the context is activate' do
    #     before {
    #       @c8.activate
    #     }
    #     it 'modifies the implementation of the method add in klass D' do
    #       expect(D.new.add(1)).to eq 21
    #     end
    #     context 'when the context is deactivate' do
    #       before {
    #         @c8.deactivate
    #       }
    #       it 'resets the method add in klass D' do
    #         expect(D.new.add(1)).to eq 2
    #       end
    #     end
    #   end
    # end
    context 'when contexts C9 C10 are created and has an adaptation on the method foo. The adaptation of context d use proceed method' do
      before {
        reset_cop_state
        @c9 = Context.new
        @c9.adapt(C, :foo){91}
        @c9.activate
        @c10 = Context.new
        @c10.adapt(C, :foo){6 + proceed()}
        @c10.activate
      }
      it 'adapt the method foo of the klaas C' do
        expect(C.new.foo).to eq 97
      end
    end

    # context 'when contexts C9 C10 are created and has an adaptation on the method foo. The adaptation of context d use proceed method' do
    #   before {
    #     reset_cop_state
    #     @c10 = Context.new
    #     @c10.adapt(C, :foo){80}
    #     @c10.activate
    #     @c11 = Context.new
    #     @c11.adapt(C, :foo){proceed()}
    #     @c11.activate
    #   }
    #   it 'adapt the method foo of the klaas C' do
    #     expect(C.new.foo).to eq 86
    #   end
    # end
  end
  # context '#deactivate' do
  #   context 'when contexts c6 c7 are created, they adapt the same method foo from C and they are activated' do
  #     before {
  #       reset_cop_state
  #       @c6 = Context.new
  #       @c6.adapt(C, :foo){60}
  #       @c6.activate
  #       @c7 = Context.new
  #       @c7.adapt(C, :foo){70}
  #       @c7.activate
  #     }
  #     context 'when c7 is deactivated' do
  #       before {
  #         @c7.deactivate
  #       }
  #       it 'activates the context c7' do
  #         expect(C.new.foo).to eq 60
  #       end
  #       context 'when c6 is deactivated' do
  #         before {
  #           @c6.deactivate
  #         }
  #         it 'restores the default implementation of foo' do
  #           expect(C.new.foo).to eq 1
  #         end
  #       end
  #     end
  #   end
  # end
end