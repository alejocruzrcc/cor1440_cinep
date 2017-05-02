# encoding: UTF-8

class Informeauditoria < ActiveRecord::Base
  include Sip::Localizacion

  belongs_to :proyectofinanciero, 
    class_name: 'Cor1440Gen::Proyectofinanciero', 
    foreign_key: 'proyectofinanciero_id'

  validates :detalle, length: { maximum: 5000}
  validates :seguimiento, length: { maximum: 5000}
  
  default_scope { order(:id) }

  campofecha_localizado :fechaplaneada
  campofecha_localizado :fechareal

  validate :fechaplaneada_posterior_inicio
  def fechaplaneada_posterior_inicio
    if fechaplaneada && 
            proyectofinanciero &&
            proyectofinanciero.fechainicio &&
            fechaplaneada < proyectofinanciero.fechainicio then
      errors.add(:fechaplaneada,
                 "La fecha planeada debe ser posterior a la de inicio")
    end
  end


  validate :fechareal_posterior_inicio
  def fechareal_posterior_inicio
    if fechareal && 
      proyectofinanciero &&
      proyectofinanciero.fechainicio &&
      fechareal < proyectofinanciero.fechainicio then
      errors.add(:fechareal,
                 "La fecha de envío debe ser posterior a la de inicio")
    end
  end

end
