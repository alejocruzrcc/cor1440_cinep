# encoding: UTF-8

class Contrato < ActiveRecord::Base
  include Sip::Modelo
  include Sip::Localizacion

  has_one :usuario, inverse_of: :contrato

  campofecha_localizado :fechaini
  campofecha_localizado :fechafin
  flotante_localizado :salario
  flotante_localizado :salarioanterior

  mattr_accessor :procesogh

  def procesogh
    r = ""
    sep = ""
    usuario.sip_grupo.map do |g|
      if g.procesogh
        r << sep << g.procesogh.nombre
        sep ="; "
      end
    end
    return r;
  end

  validate :fechas_ordenadas
  def fechas_ordenadas
    if fechaini && fechafin && fechaini > fechafin
      errors.add(:fechafin, 
                 "La fecha de terminación debe ser posterior a la de inicio")
    end
  end

end
