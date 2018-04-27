# encoding: UTF-8

require 'jn316_gen/concerns/models/usuario'

class Usuario < ActiveRecord::Base
  include Jn316Gen::Concerns::Models::Usuario

  devise :database_authenticatable, :rememberable, 
    :trackable, :lockable

  belongs_to :cajacompensacion, validate: true

  belongs_to :cargo, validate: true

  belongs_to :contrato, validate: true
  accepts_nested_attributes_for :contrato, reject_if: :all_blank

  belongs_to :empresaps, validate: true

  belongs_to :fondopensiones, validate: true

  belongs_to :labdepartamento, class_name: 'Sip::Departamento',
    foreign_key: "labdepartamento_id", validate: true
  
  belongs_to :labmunicipio, class_name: 'Sip::Municipio',
    foreign_key: "labmunicipio_id", validate: true

  belongs_to :niveleducacion, class_name: "::Niveleducacion",
    foreign_key: "niveleducacion_id", validate: true

  belongs_to :oficina, class_name: 'Sip::Oficina',
    foreign_key: "oficina_id", validate: true

  belongs_to :perfilprofesional, validate: true
  
  belongs_to :persona, class_name: 'Sip::Persona',
    foreign_key: "persona_id", validate: true
  accepts_nested_attributes_for :persona, reject_if: :all_blank

  belongs_to :profesion, validate: true


  #attr labmundep

  def labmundep
    if labdepartamento_id && labmunicipio_id
      labdepartamento.nombre + " / " + labmunicipio.nombre
    elsif labdepartamento_id
      labdepartamento.nombre 
    else
      ""
    end
  end

  def labmundep=(v)
    labdepartamento_id = labmunicipio_id = nil
    pmd = v.split(" / ")
    if pmd.length == 1 # solo departamento
      ldep = Sip::Departamento.all.where('nombre=?', pmd[0])
      ldep = ldep.where(
        'id_pais=?', 170) # Colombia
      dep = ldep.take
      if dep
        labdepartamento_id = dep.id
      end
    else # departamento y municipio
      ldep = Sip::Departamento.all.where('nombre=?', pmd[1])
      ldep = ldep.where(
        'id_pais=?', 170) # Colombia
      dep = ldep.take
      if dep
        labdepartamento_id = dep.id
        mun = Sip::Municipio.all.where(
          'nombre=? AND id_departamento=?', pmd[0], dep.id).take
        if mun
          labmunicipio_id = mun.id
        end
      end
    end
  end

  cattr_accessor :gruposysupragrupos

  def gruposysupragrupos
    ApplicationHelper.supergrupos_usuario(self).join("; ")
  end

  mattr_accessor :areaestudios
  def areaestudios
    if profesion && profesion.areaestudios
      profesion.areaestudios.nombre
    else
      'SIN INFORMACIÓN'
    end
  end

  mattr_accessor :tipocontrato_id
  def tipocontrato_id
    if contrato && contrato.tipocontrato 
      contrato.tipocontrato.id
    else
      1
    end
  end

  attr_accessor :habilitado

  def habilitado
    fechadeshabilitacion.nil? ? 'SI' : 'NO'
  end


  def gruposesp
    sip_grupo.map(&:nombre).join("; ")
  end

  def grupos 
    ApplicationHelper.supergrupos_usuario(self).join("; ")
  end

  def fechaini_localizada
    if contrato
      contrato.fechaini_localizada
    else
      ""
    end
  end

  def fechafin_localizada
    if contrato
      contrato.fechafin_localizada
    else
      ""
    end
  end


  def fechanacb
    r = ""
    if persona.anionac
      r += persona.anionac.to_s
    end
    r += " - "
    if persona.mesnac
      r += persona.mesnac.to_s
    end
    r += " - "
    if persona.dianac
      r += persona.dianac.to_s
    end
    return r
  end
 
  def lugardocumento
    if persona
      persona.lugardocumento
    else
      ""
    end
  end

  def lugarnacimiento
    r = ""
    if persona && persona.pais
      r += persona.pais.nombre
      if persona.departamento
        r += " / " + persona.departamento.nombre
        if persona.municipio
          r += " / " + persona.municipio.nombre
          if persona.clase
            r += " / " + persona.clase.nombre
          end
        end
      end
    end

    return r
  end

  def numerocontrato
    if contrato
      contrato.numero
    else
      ""
    end
  end

  def numerodocumento
    if persona
      persona.numerodocumento
    else
      ""
    end
  end

  def procesogh
    if contrato && contrato.procesogh
      contrato.procesogh
    else
      ""
    end
  end


  def salario
    if contrato
      contrato.salario
    else
      ""
    end
  end

  def salarioanterior
    if contrato
      contrato.salarioanterior
    else
      ""
    end
  end

  def tdocumento
    if persona && persona.tdocumento
      persona.tdocumento.nombre
    else
      ""
    end
  end
 
  def tipocontrato
    if contrato && contrato.tipocontrato
      contrato.tipocontrato.nombre
    else
      ""
    end
  end

  def tiponomina
    if contrato && contrato.tiponomina
      contrato.tiponomina
    else
      ""
    end
  end


  validates_presence_of :nombres
  validates_presence_of :apellidos
  validates :direccionresidencia, length: { maximum: 255}
  validates :extension, length: { maximum: 128}
  validates :telefonos, length: { maximum: 256}
  validates :numhijos, :numericality => { :greater_than_or_equal_to => 0 }
  validates :numhijosmen12, :numericality => { :greater_than_or_equal_to => 0 }

  has_many :actividad_usuario, dependent: :delete_all,
    class_name: 'Cor1440Gen::ActividadUsuario',
    foreign_key: 'usuario_id'
  has_many :actividad, through: :actividad_usuario,
    class_name: 'Cor1440Gen::Actividad'

  has_many :anexo_usuario, dependent: :delete_all,
    class_name: '::AnexoUsuario',
    foreign_key: 'usuario_id', validate: true
  accepts_nested_attributes_for :anexo_usuario, 
    allow_destroy: true, reject_if: :all_blank
  has_many :sip_anexo, :through => :anexo_usuario, 
    class_name: 'Sip::Anexo'
  accepts_nested_attributes_for :sip_anexo,  reject_if: :all_blank

  has_many :coordinador_proyectofinanciero, #dependent: :destroy,
    class_name: '::CoordinadorProyectofinanciero',
    foreign_key: 'coordinador_id'

  has_many :proyectofinanciero_uresponsable, #dependent: :destroy,
    class_name: '::ProyectofinancieroUresponsable',
    foreign_key: 'uresponsable_id'

  has_many :proyectofinanciero_usuario, #dependent: :destroy,
    class_name: '::ProyectofinancieroUsuario',
    foreign_key: 'usuario_id'
  has_many :proyectofinanciero, through: :proyectofinanciero_usuario,
    class_name: 'Cor1440Gen::Proyectofinanciero'

  has_many :vinculacion, dependent: :delete_all,
    class_name: '::Vinculacion',
    foreign_key: 'usuario_id', validate: true
  accepts_nested_attributes_for :vinculacion, 
    allow_destroy: true, reject_if: :all_blank

  before_destroy :usuario_sin_proyectofinanciero

  def presenta_nombre
    if self.nombres
      r = self.nombres + ' ' + self.apellidos
    else
      r = self.nusuario
    end
    return r.strip
  end

  scope :filtro_oficina_id, lambda {|o|
    where(oficina_id: o)
  }

  scope :filtro_sip_grupo_ids, lambda {|g|
    where(grupo_id: g)
  }

  scope :filtro_habilitado, lambda {|o|
    if o.upcase.strip == 'SI'
      where(fechadeshabilitacion: nil)
    elsif o.upcase.strip == 'NO'
      where.not(fechadeshabilitacion: nil)
    end 
  }


  protected

  def usuario_sin_proyectofinanciero
    return true if proyectofinanciero_usuario.count == 0
    m = "El usuario aparece en compromiso(s) institucional"
    errors.add :base, m
    throw(:abort)
  end


end
