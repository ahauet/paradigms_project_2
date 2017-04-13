class ContextManagement

  def initialize
    @contexts = Array.new
  end

  @@instance = ContextManagement.new

  def self.instance
    return @@instance
  end

  def add(context)
    @contexts.push(context)
  end

  def contains(adaptation)
    @contexts.each { |x|
      if (adaptation.context == x.context)
        return true
      end
    }
    return false
  end

  def define_in_default_contains(klass, method)
    define = false
    default_context = @contexts[-1]
    default_context.adaptations.each { |x|
      if(x.klass == klass && x.method_missing == method)
        define = true
      end
    }
    if(!define)
      impl = @default_impl.bind(@klass.new)
      default_context.adapt(klass, method, impl)
    end
  end

end