def proceed(*args)
  context = ProceedManager.instance.context
  klass = ProceedManager.instance.klass
  method = ProceedManager.instance.method_name
  adaptation = ContextManager.instance.get_previous_adaptation_for_proceed(context, klass, method)
  if adaptation != nil
    if adaptation.impl.class == UnboundMethod
      adaptation.impl.bind(adaptation.klass.class_eval("self.new")).call
    else
      ProceedManager.instance.klass = adaptation.klass
      ProceedManager.instance.method_name =  adaptation.method_name
      ProceedManager.instance.context =  adaptation.context
      adaptation.impl.call()
    end
  end
end


def reset_cop_state
  Context.reset_cop_state
end
############################################
#
# Context
#
###########################################
class Context

  attr_accessor :adaptations

  def initialize
    @active = false
    @adaptations = Array.new
  end

  def active?
    @active
  end

  def activate
    @active = true
    # If the context is already active, we will
    # remove it from the stack and will add it
    # on the top

    if @active
      ContextManager.instance.remove(self)
    end
    ContextManager.instance.add(self)
    # We will deploy the adaptations
    @adaptations.each do |adaptation|
      adaptation.deploy
    end
  end

  def deactivate
    @active = false

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
    adaptation = Adaptation.new(self, klass, method, impl)
    @adaptations.push(adaptation)
    if @active
      adaptation.deploy
    end
  end

  def unadapt (klass,	method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass && adaptation.method_name == method
        tmp = adaptation
        @adaptations.delete(tmp)
        if @active
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

  attr_accessor :klass, :method_name, :impl, :context


  def initialize(context, klass, method_name, impl)
    @context = context
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
      if impl.class == UnboundMethod
        name = @method_name
        impl = @impl
        @klass.send(:define_method, name, impl)
      else
        klass = @klass
        name = @method_name
        impl = @impl
        context = @context
        @klass.send(:define_method, name, lambda do |*args|
          ProceedManager.instance.klass = klass
          ProceedManager.instance.method_name = name
          ProceedManager.instance.context = context
          impl.call(*args)
        end)
      end
  end

  def deploy_default
    @klass.class_eval{ define_method(name, impl)}
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

  def print_context
    puts 'CONTEXT'
    @contexts.each do |context|
      puts context
    end
  end

  def add(context)
    @contexts.unshift(context)
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
      @default_implementation.push(Adaptation.new(nil,klass, method, impl))
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

  def get_previous_adaptation_for_proceed(context,klass,method_name)
    previous = false
    @contexts.each do |pcontext|
      if !previous
        if pcontext == context
          previous = true
        end
      else
        new_adaptation = pcontext.find(klass, method_name)
        if new_adaptation != nil
          return new_adaptation
        end
      end
    end
    @default_implementation.each do |default_adaptation|
      if klass == default_adaptation.klass  && method_name == default_adaptation.method_name
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
    ProceedManager.instance.reset
  end

  private_class_method :new
end
class ProceedManager

  attr_accessor :method_name, :klass, :context

  def initialize
    @context = nil
    @method_name = nil
    @klass = nil
  end

  def print
    puts "context #{@context} - klass #{@klass} - method_name #{@method_name}"
  end

  @@instance = ProceedManager.new

  def self.instance
    return @@instance
  end

  def reset
    @context = nil
    @method_name = nil
    @klass = nil
  end

  private_class_method :new
end
