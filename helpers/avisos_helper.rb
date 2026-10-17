module AvisosHelper
  def avisos_pendientes_count
    return @avisos_pendientes_count if defined?(@avisos_pendientes_count)
    @avisos_pendientes_count = autenticado? ? AvisoService.pendientes_count : 0
  end

  def avisos_pendientes_lista
    return [] unless autenticado?
    @avisos_pendientes_lista ||= AvisoService.pendientes.first(10)
  end
end