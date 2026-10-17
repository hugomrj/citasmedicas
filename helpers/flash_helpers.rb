module FlashHelpers
  # Flash basado en sesión. Evita depender de gemas extra.
  # Uso: flash[:success] = 'OK'  ·  en la vista: flash.each { ... }
  def flash
    @flash ||= FlashProxy.new(session)
  end

  class FlashProxy
    def initialize(session)
      @session = session
    end

    def [](key)
      store[key.to_s]
    end

    def []=(key, value)
      store[key.to_s] = value
    end

    def each(&block)
      return enum_for(:each) unless block
      pendientes.each(&block)
    end

    def empty?
      pendientes.empty?
    end

    # Devuelve el hash y lo limpia al mismo tiempo (one-shot).
    def pendientes
      actuales = (store || {}).dup
      @session[:flash] = {}
      actuales
    end

    private

    def store
      @session[:flash] ||= {}
    end
  end
end