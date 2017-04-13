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
    if @active
      ContextManager.instance.remove(self)
    end
    ContextManager.instance.add(self)
    @adaptations.each do |adaptation|
      adaptation.deploy
    end
    @active = true
  end

  def deactivate
    ContextManager.instance.contexts.length
    ContextManager.instance.remove(self)
    new_adaptation = nil
    @adaptations.each do |adaptation|
      new_adaptation = ContextManager.instance.get_previous_adaptation(adaptation)
    end
    if new_adaptation != nil
      @active = false
      new_adaptation.deploy
    end
  end

  def adapt	(klass,	method,	&impl)
    ContextManager.instance.save_default_context(klass, method)
    @adaptations.push(Adaptation.new(klass, method, impl))
  end

  def unadapt	(klass,	method)
  end

  def contains(klass, method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass  && adaptation.method_name == method
        return true
      end
    end
    false
  end

  def find(klass, method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass  && adaptation.method_name == method
        return adaptation
      end
    end
    nil
  end

  def reset_cop_state
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

  def initialize(klass,method_name,impl)
    @klass = klass
    @method_name = method_name
    @impl = impl
  end

  def deploy
    name = @method_name
    impl = @impl
    @klass.class_eval{ define_method(name, impl) }
  end
end
############################################
#
# Adaptation
#
###########################################
class ContextManager

  attr_accessor :contexts

  def initialize
    @contexts = Array.new
    @default_implementation = Array.new
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
    has = false
    @default_implementation.each do |adaptation|
      if adaptation.klass == klass  && adaptation.method_name == method
        has = true
      end
    end
    if !has
      impl = klass.instance_method(method)
      @default_implementation.push(Adaptation.new(klass, method, impl))
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
    return nil
  end

  def reset
    @contexts = Array.new
    @default_implementation.each do |adaptation|
      adaptation.deploy
    end
  end

  private_class_method :new
end