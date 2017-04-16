def reset_cop_state
  Context.reset_cop_state
end
############################################
#
# Context
#
###########################################
class Context

  attr_accessor :adaptations, :count

  def initialize
    @adaptations = Array.new
    @count = 0
  end

  def active?
    @count > 0
  end

  def activate
    @count = @count + 1
    if !ContextManager.instance.contexts.include? self
      ContextManager.instance.add(self)
    end
    context = ContextManager.instance.get_current_context
    context.activate_context
  end

  def activate_context
    # We will deploy the adaptations
    @adaptations.each do |adaptation|
      adaptation.deploy
    end
  end

  def deactivate
    if @count > 0
      @count = @count - 1
    end
  end

  def deactivate_context
    ContextManager.instance.remove(self)

    new_adaptation = nil


    @adaptations.each do |adaptation|
      new_adaptation = ContextManager.instance.get_previous_adaptation(adaptation)
    end

    if new_adaptation != nil
      new_adaptation.deploy
    end

  end


  def adapt	(klass,	method,	&impl)
    adaptation = Adaptation.new(klass, method, impl)
    @adaptations.push(adaptation)
    if @count > 0
      adaptation.deploy
    end
  end

  def unadapt (klass,	method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass && adaptation.method_name == method
        tmp = adaptation
        @adaptations.delete(tmp)
        if @count > 0
          new_adaptation = ContextManager.instance.get_previous_adaptation(tmp)
          if new_adaptation != nil
            new_adaptation.deploy
          else
            if ContextManager.instance.contains_in_foreign_implementation(klass, method)
              tmp.undeploy
              ContextManager.instance.remove_foreign_implementation(tmp)
            end
          end
        end
      end
    end
  end

  def find(klass, method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass  && adaptation.method_name == method
        return adaptation
      end
    end
    nil
  end

  def self.proceed(caller,klass, method, impl)
    klass.instance_methods(false).each do |meth|
      puts klass.instance_method(meth).to_r == impl
    end
  end

  def self.reset_cop_state
    ContextManager.instance.reset
  end
end
############################################
#
# Adaptation
#
###########################################
class Adaptation

  attr_accessor :klass, :method_name, :impl


  def initialize(klass, method_name, impl)
    @klass = klass
    @method_name = method_name
    @impl = impl
  end

  def deploy
    if @klass.instance_methods(false).include?(@method_name)
      ContextManager.instance.save_default_context( @klass, @method_name)
    else
      ContextManager.instance.save_foreign_implementation(self)
    end
    klass = @klass
    name = @method_name
    impl = @impl
    @klass.class_eval{ define_method(name, impl)
    define_method(:proceed){
      puts caller.first
      Context.proceed(self,klass,name,impl)
    }}
  end

  def undeploy
    name = @method_name
    @klass.send(:remove_method, name)
  end
end
############################################
#
# ContextManager
#
###########################################
class ContextManager

  attr_accessor :contexts

  def initialize
    @contexts = Array.new
    @default_implementation = Array.new
    @foreign_implementation = Array.new
  end

  @@instance = ContextManager.new

  def self.instance
    return @@instance
  end

  def add(context)
    @contexts.push(context)
  end

  def remove(context)
    @contexts.delete(context)
  end

  def save_default_context(klass, method)
    already_have = false
    @default_implementation.each do |adaptation|
      if adaptation.klass == klass  && adaptation.method_name == method
        already_have = true
      end
    end

    if !already_have && !contains_in_foreign_implementation(klass, method)
      impl = klass.instance_method(method)
      @default_implementation.push(Adaptation.new(klass, method, impl))
    end
  end

  def contains_in_foreign_implementation(klass, method)
    @foreign_implementation.each do |adaptation|
      if adaptation.klass == klass  && adaptation.method_name == method
        return true
      end
    end
    return false
  end

  def save_foreign_implementation(adaptation)
    already_have = false
    @foreign_implementation.each do |fadaptation|
      if fadaptation.klass == adaptation.klass  && fadaptation.method_name == adaptation.method_name
        already_have = true
      end
    end
    if !already_have
      @foreign_implementation.push(adaptation)
    end
  end

  def get_previous_adaptation(adaptation)
    @contexts.each do |context|
      new_adaptation = context.find(adaptation.klass, adaptation.method_name)
      if new_adaptation != nil
        return new_adaptation
      end
    end
    @default_implementation.each do |default_adaptation|
      if adaptation.klass == default_adaptation.klass  && adaptation.method_name == default_adaptation.method_name
        return default_adaptation
      end
    end
    nil
  end

  def remove_foreign_implementation(adaptation)
    @foreign_implementation.each do |fadaptation|
      if fadaptation.klass == adaptation.klass  && fadaptation.method_name == adaptation.method_name
        @foreign_implementation.delete(fadaptation)
      end
    end
  end

  def get_current_context
    result = nil
    if @contexts.length > 0
      result = @contexts.first
      @contexts.each do |context|
        if context.count > result.count
          result = context
        end
      end
    end
    result
  end

  def reset
    @foreign_implementation.each do |adaptation|
      adaptation.undeploy
    end
    @default_implementation.each do |adaptation|
      adaptation.deploy
    end
    @contexts = Array.new
    @default_implementation = Array.new
    @foreign_implementation = Array.new
  end

  private_class_method :new
end