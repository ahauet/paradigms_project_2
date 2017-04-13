#Context
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
    ContextManager.instance.add(self)
    @active = true
    @adaptations.each do |adaptation|
      adaptation.deploy
    end
  end

  def deactivate
    puts "DEactivate"
    ContextManager.instance.remove(self)
    @adaptations.each do |adaptation|
      new_adaptation = ContextManager.instance.get_adaptation(adaptation)

      if new_adaptation != nil
        puts new_adaptation.klass
        new_adaptation.deploy
      end
    end
  end

  def adapt	(klass,	method,	&impl)
    @adaptations.push(Adaptation.new(klass, method, impl))
  end

  def unadapt	(klass,	method);	end

  # Indicate if the context adapt a method of a specific klass
  def adapt_such(klass, method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass && adaptation.method_name == method
        return adaptation
      end
    end
    nil
  end

  def contains(klass, method)
    @adaptations.each do |adaptation|
      if adaptation.klass == klass && adaptation.method_name == method
        return true
      end
    end
    false
  end

  def self.reset_cop_state
    #ContextManager.instance.reset
    ContextManager.instance.contexts.each do |context|
      puts ContextManager.instance.contexts.length
      context.deactivate
      puts ContextManager.instance.contexts.length
    end
  end
end

# Adaptation
class Adaptation

  attr_accessor :klass, :method_name, :impl

  def initialize(klass,method,impl)
    @klass = klass
    @method_name = method
    @impl = impl
  end

  def deploy
    puts "DEPLOY"
    nom = @method_name
    impl = @impl
    puts nom
    #puts impl.bind(@klass.new).call
    @klass.send(:define_method,@method_name,@impl)
    #@klass.class_eval{ define_method(nom, impl) }
  end
end


#ContextManager
class ContextManager

  attr_accessor :contexts

  def initialize
    @contexts = Array.new
    @default_context = Context.new
    puts @contexts.length
  end

  @@instance = ContextManager.new

  def self.instance
    return @@instance
  end

  def add (context)
    puts "ADD"
    context.adaptations.each do |adaptation|
      if  !@default_context.contains(adaptation.klass, adaptation.method_name)
        method = adaptation.klass.instance_method(adaptation.method_name)
        impl = method.bind(adaptation.klass.new).call
        @default_context.adapt(adaptation.klass,adaptation.method_name){impl}
      end
    end
    @contexts.push(context)
  end

  def remove(context)
    puts 'DELETE'
    @contexts.delete(context)

  end

  def get_adaptation(adaptation)
    @contexts.each do |context|
      result = context.adapt_such(adaptation.klass, adaptation.method_name)
      if result != nil
        return result
      end
    end
    return @default_context.adapt_such(adaptation.klass, adaptation.method_name)
  end

  private_class_method :new
end