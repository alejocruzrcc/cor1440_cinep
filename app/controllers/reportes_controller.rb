# encoding: UTF-8

class ReportesController < ::ApplicationController

  include Sip::ConsultasHelper

  # Indicador 1.1
  def indicador11
    pFaini = param_escapa('fechaini')
    pFafin = param_escapa('fechafin')

    cons = "SELECT DISTINCT cor1440_gen_actividad.nombre as act_nombre, 
    redactor.nombre as red_nombre, 
    sip_municipio.nombre as municipio, sip_departamento.nombre as departamento, 
    (CASE WHEN alcance = 'Local' THEN 'X' ELSE '' END) AS local,
    (CASE WHEN alcance = 'Regional' THEN 'X' ELSE '' END) AS regional,
    (CASE WHEN alcance = 'Nacional' THEN 'X' ELSE '' END) AS nacional,
    (CASE WHEN alcance = 'Internacional' THEN 'X' ELSE '' END) AS internacional,
    nucleoconflicto.nombre as nucleoconflicto,
    ARRAY_TO_STRING(
      ARRAY(SELECT nucleoconflicto.nombre FROM actividad_nucleoconflicto 
      JOIN nucleoconflicto 
      ON actividad_nucleoconflicto.nucleoconflicto_id=nucleoconflicto.id 
      WHERE actividad_nucleoconflicto.actividad_id=cor1440_gen_actividad.id), 
      '; ') as otrosnucleos,
    ARRAY_TO_STRING(
      ARRAY(SELECT publicacion.nombre FROM actividad_publicacion
      JOIN publicacion
      ON actividad_publicacion.publicacion_id=publicacion.id 
      WHERE actividad_publicacion.actividad_id=cor1440_gen_actividad.id),
      '; ') as publicaciones
    FROM cor1440_gen_actividad JOIN actividad_publicacion 
        ON cor1440_gen_actividad.id=actividad_publicacion.actividad_id 
      LEFT JOIN redactor ON cor1440_gen_actividad.redactor_id=redactor.id 
      LEFT JOIN sip_municipio 
        ON cor1440_gen_actividad.municipio_id=sip_municipio.id
      LEFT JOIN sip_departamento
        ON cor1440_gen_actividad.departamento_id=sip_departamento.id
      LEFT JOIN nucleoconflicto
        ON cor1440_gen_actividad.nucleoconflicto_id=nucleoconflicto.id"
    where = ''
    if (pFaini != '') 
      where = " WHERE cor1440_gen_actividad.fecha >= '#{pFaini}'"
    end
    if (pFafin != '')
      if where == ''
        where += ' AND '
      else
        where = ' WHERE '
      end
      where += "cor1440_gen_actividad.fecha <= '#{pFafin}'"
    end
    cons += where
    @cuerpotabla = ActiveRecord::Base.connection.select_all(cons)

    @enctabla = ['Escenario de Toma de Decisión',
      'Red Vinculada', 'Municipio', 'Departamento', 
      'Local', 'Regional', 'Nacional', 'Internacional', 
      'Principal núcleo que transforma', 
      'Otros núcleos que transforma', 'Insumo con el que se participa'
    ]

    respond_to do |format|
      format.html {  }
      format.json { head :no_content }
      format.js   { render 'sip/reportes/cambiatabla' }
    end
  end

  def respuestas
    @pque = { 'derecho' => 'Derecho vulnerado',
      'ayudaestado' => 'Ayuda del Estado',
      'ayudasjr' => 'Ayuda Humanitaria del SJR',
      'motivosjr' => 'Servicio/Asesoria del SJR',
      'progestado' => 'Subsidio/Programa del Estado'
    }

    pFaini = param_escapa('fechaini')
    pFafin = param_escapa('fechafin')
    pContar = param_escapa('contar')
    pOficina = param_escapa('oficina')

    if (pContar == '') 
      pContar = 'derecho'
    end

    cons1 = 'cres1'
    # La estrategia es 
    # 1. Agrupar en la vista cons1 respuesta con lo que se contará 
    #    restringiendo por filtros con códigos 
    # 2. Contar derechos/respuestas cons1, cambiar códigos
    #    por información por desplegar

    # Para la vista cons1 emplear que1, tablas1 y where1
    que1 = 'caso.id AS id_caso, respuesta.fechaatencion AS fechaatencion'
    tablas1 = 'sivel2_gen_caso AS caso, sivel2_sjr_casosjr AS casosjr, ' +
      'sivel2_sjr_respuesta AS respuesta'
    where1 = ''

    # Para la consulta final emplear arreglo que3, que tendrá parejas
    # (campo, titulo por presentar en tabla)
    que3 = []
    tablas3 = cons1
    where3 = ''

    # where1 = consulta_and(where1, 'caso.id', GLOBALS['idbus'], '<>')
    where1 = consulta_and_sinap(where1, "caso.id", "casosjr.id_caso")
    where1 = consulta_and_sinap(where1, "caso.id", "respuesta.id_caso")
    if (pFaini != '') 
      where1 = consulta_and(
        where1, "respuesta.fechaatencion", pFaini, ">="
      )
    end
    if (pFafin != '') 
      where1 = consulta_and(
        where1, "respuesta.fechaatencion", pFafin, "<="
      )
    end

    if (pOficina != '') 
      where1 = consulta_and(where1, "casosjr.id_regionsjr", pOficina)
    end

    que1 = agrega_tabla(que1, "casosjr.id_regionsjr AS id_regionsjr")
    trel = "#{pContar}_respuesta"
    idrel = "id_#{pContar}"
    case (pContar) 
    when 'ayudasjr', 'ayudaestado', 'derecho', 'motivosjr', 'progestado'
      que1 = agrega_tabla(que1, "#{trel}.#{idrel} AS #{idrel}")
      where1 = consulta_and_sinap(
        where1, "respuesta.id", "#{trel}.id_respuesta"
      )
      #where1 = consulta_and_sinap( where1, "respuesta.fechaatencion", "#{trel}.fechaatencion")
      tablas1 = agrega_tabla(tablas1, "sivel2_sjr_#{trel} AS #{trel}")
      tablas3 = agrega_tabla(tablas3, "sivel2_sjr_#{pContar} AS #{pContar}")
      where3 = consulta_and_sinap(where3, idrel, "#{pContar}.id")
      que3 << ["#{pContar}.nombre", @pque[pContar]]
    else
      puts "opción desconocida #{pContar}"
    end

    ActiveRecord::Base.connection.execute "DROP VIEW  IF EXISTS #{cons1}"

    # Filtrar 
    q1="CREATE VIEW #{cons1} AS 
            SELECT #{que1}
            FROM #{tablas1} WHERE #{where1}"
    #puts "q1 es #{q1}"
    ActiveRecord::Base.connection.execute q1

    #puts que3
    # Generamos 1,2,3 ...n para GROUP BY
    gb = sep = ""
    qc = ""
    i = 1
    que3.each do |t|
      if (t[1] != "") 
        gb += sep + i.to_s
        qc += t[0] + ", "
        sep = ", "
        i += 1
      end
    end

    @coltotales = [i-1, i]
    if (gb != "") 
      gb ="GROUP BY #{gb} ORDER BY #{i} DESC"
    end
    que3 << ["", "Cantidad atenciones"]
    twhere3 = where3 == "" ? "" : "WHERE " + where3
    q3 = "SELECT #{qc}
        COUNT(cast(#{cons1}.id_caso as text) || ' '
        || cast(#{cons1}.fechaatencion as text))
        FROM #{tablas3}
        #{twhere3}
        #{gb}
    "
    #puts "q3 es #{q3}"
    @cuerpotabla = ActiveRecord::Base.connection.select_all(q3)

    @enctabla = []
    que3.each do |t|
      if (t[1] != "") 
        @enctabla << CGI.escapeHTML(t[1])
      end
    end


    respond_to do |format|
      format.html { }
      format.json { head :no_content }
      format.js   { render 'resultado' }
    end


  end

  def personas
    authorize! :contar, Sivel2Gen::Caso
    pFaini = param_escapa('faini')
    pFafin = param_escapa('fafin') 
    pSegun = param_escapa('segun')
    pOficina = param_escapa('oficina')
    pMunicipio = param_escapa('municipio')
    pDepartamento = param_escapa('departamento')

    # La estrategia es 
    # 1. Agrupar en la vista cons1 personas con lo que se contará 
    #    restringiendo por filtros con códigos sin desp. ni info geog.
    # 2. En vista cons2 dejar lo mismo que en cons1, pero añadiendo
    #    expulsión más reciente y su ubicacion si la hay.
    #    Al añadir info. geográfica no es claro
    #    cual poner, porque un caso debe tener varias ubicaciones 
    #    correspondientes a los sitios por donde ha pasado durante
    #    desplazamientos.  Estamos suponiendo que interesa
    #    el sitio de la ultima expulsion.
    # 3. Contar beneficiarios contactos sobre cons2, cambiar códigos
    #    por información por desplegar
    # 4. Contar beneficiarios no contactos sobre cons2, cambiar códigos
    #    por información por desplegar

    # Validaciones todo caso es casosjr y viceversa
    # Validaciones todo caso tiene victima
    # Validaciones todo caso tiene ubicacion

    cons1 = 'cben1';
    cons2 = 'cben2';
    cons3 = 'cben3';
    @fechaini = '';
    where1 = '';
    if (params[:fechaini] && params[:fechaini] != "") 
        pfechaini = DateTime.strptime(params[:fechaini], '%Y-%m-%d')
        @fechaini = pfechaini.strftime('%Y-%m-%d')
        where1 = consulta_and(
          where1, "casosjr.fecharec", @fechaini, ">="
        )
    end
    @fechafin = '';
    if (params[:fechafin] && params[:fechafin] != "") 
        pfechafin = DateTime.strptime(params[:fechafin], '%Y-%m-%d')
        @fechafin = pfechafin.strftime('%Y-%m-%d')
        where1 = consulta_and(
          where1, "casosjr.fecharec", @fechafin, "<="
        )
    end
    que1 = 'caso.id AS id_caso, victima.id_persona AS id_persona,
            CASE WHEN (casosjr.contacto=victima.id_persona) THEN 1 ELSE 0 END 
            AS contacto, 
            CASE WHEN (casosjr.contacto<>victima.id_persona) THEN 1 ELSE 0 END
            AS beneficiario, 
            1 as npersona'
    tablas1 = 'sivel2_gen_caso AS caso, sivel2_sjr_casosjr AS casosjr, 
    sivel2_gen_victima AS victima'
    

    # Para la consulta final emplear arreglo que3, que tendrá parejas
    # (campo, titulo por presentar en tabla)
    que3 = []
    tablas3 = "#{cons2}"
    where3 = ''

#    consulta_and(where1, 'caso.id', GLOBALS['idbus'], '<>')
    where1 = consulta_and_sinap(where1, "caso.id", "casosjr.id_caso")
    where1 = consulta_and_sinap(where1, "caso.id", "victima.id_caso")
       
    if (pOficina != '') 
      where1 = consulta_and(where1, "casosjr.id_regionsjr", pOficina)
    end
    #byebug
    case pSegun
    when ''
      titSegun = 'Total'
      que1 = agrega_tabla(que1, 'cast(\'total\' as text) as total')
      que3 << ["", ""]
    when 'RANGO DE EDAD'
      que1 = agrega_tabla(que1, 'victima.id_rangoedad AS id_rangoedad')
      tablas3 = agrega_tabla(tablas3, 'sivel2_gen_rangoedad AS rangoedad')
      where3 = consulta_and_sinap(where3, "id_rangoedad", "rangoedad.id")
      que3 << ["rangoedad.rango", "Edad"]
    when 'SEXO'
      que1 = agrega_tabla(que1, 'persona.sexo AS sexo')
      tablas1 = agrega_tabla(tablas1, 'sivel2_gen_persona AS persona')
      where1 = consulta_and_sinap(where1, "persona.id", "victima.id_persona")
      que3 << ["sexo", "Sexo"]
    when 'ACTIVIDAD / OFICIO'
      que1 = agrega_tabla(que1, 'victimasjr.id_actividadoficio AS id_actividadoficio')
      tablas1 = agrega_tabla(tablas1, 'sivel2_sjr_victimasjr AS victimasjr')
      where1 = consulta_and_sinap(where1, "victima.id", "victimasjr.id_victima")
      tablas3 = agrega_tabla(tablas3, 'sivel2_gen_actividadoficio AS actividadoficio ')
      where3 = consulta_and_sinap(where3, "id_actividadoficio", "actividadoficio.id")
      que3 << ["actividadoficio.nombre", "Actividad / Oficio"]
    when 'MES RECEPCIÓN'
      que1 = agrega_tabla(que1, "extract(year from fecharec) || '-' " +
                   "|| lpad(cast(extract(month from fecharec) as text), 2, " +
                   "cast('0' as text)) as mes")
      que3 << ["mes", "Mes"]
    else
      puts "opción desconocida pSegun=#{pSegun}"
    end

    ActiveRecord::Base.connection.execute "DROP VIEW  IF EXISTS #{cons2}"
    ActiveRecord::Base.connection.execute "DROP VIEW  IF EXISTS #{cons1}"

    if where1 != ''
      where1 = 'WHERE ' + where1
    end
    # Filtrar 
    q1="CREATE VIEW #{cons1} AS 
        SELECT #{que1}
        FROM #{tablas1} #{where1}"
    #puts "OJO q1 es #{q1}<hr>"
    ActiveRecord::Base.connection.execute q1

    # Paso 2
    # Añadimos información geográfica que se pueda
    q2="CREATE VIEW #{cons2} AS SELECT s.*,
            ubicacion.id_departamento, 
            departamento.nombre AS departamento_nombre, 
            ubicacion.id_municipio, municipio.nombre AS municipio_nombre, 
            ubicacion.id_clase, clase.nombre AS clase_nombre
            FROM (SELECT cben1.*, MAX(fechaexpulsion) as fmax FROM cben1 
            LEFT JOIN sivel2_sjr_desplazamiento ON
            (cben1.id_caso=sivel2_sjr_desplazamiento.id_caso) 
            GROUP BY 1,2,3,4,5,6) AS s
            LEFT JOIN sivel2_sjr_desplazamiento ON
            (s.id_caso = sivel2_sjr_desplazamiento.id_caso 
             AND sivel2_sjr_desplazamiento.fechaexpulsion=s.fmax)
            LEFT JOIN sivel2_gen_ubicacion AS ubicacion ON 
              (sivel2_sjr_desplazamiento.id_expulsion = ubicacion.id) 
            LEFT JOIN sivel2_gen_departamento AS departamento ON 
              (ubicacion.id_pais=departamento.id_pais 
                AND ubicacion.id_departamento=departamento.id) 
            LEFT JOIN sivel2_gen_municipio AS municipio ON 
              (ubicacion.id_pais=municipio.id_pais 
                AND ubicacion.id_departamento=municipio.id_departamento
                AND ubicacion.id_municipio=municipio.id)
            LEFT JOIN sivel2_gen_clase AS clase ON 
              (ubicacion.id_pais=municipio.id_pais
                AND ubicacion.id_departamento=clase.id_departamento
                AND ubicacion.id_municipio=clase.id_municipio 
                AND ubicacion.id_clase=clase.id )
            GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13"

    #puts "OJO q2 es #{q2}<hr>"
    ActiveRecord::Base.connection.execute q2

    if (pDepartamento == "1") 
      que3 << ["departamento_nombre", "Último Departamento Expulsor"]
    end
    if (pMunicipio== "1") 
      que3 << ["municipio_nombre", "Último Municipio Expulsor"]
    end
    #puts "OJO que3 es #{que3}"
    # Generamos 1,2,3 ...n para GROUP BY
    gb = sep = ""
    qc = ""
    i = 1
    que3.each do |t|
      if (t[1] != "") 
        gb += sep + i.to_s
        qc += t[0] + ", "
        sep = ", "
        i += 1
      end
    end
    if (gb != "") 
      gb ="GROUP BY #{gb} ORDER BY #{gb}"
    end
    @coltotales = [i-1, i, i+1]
    que3 << ["", "Contactos"]
    que3 << ["", "Beneficiarios"]
    que3 << ["", "Total"]
    twhere3 = where3 == "" ? "" : "WHERE " + where3
    q3="SELECT #{qc}
            SUM(#{cons2}.contacto) AS contacto, 
            SUM(#{cons2}.beneficiario) AS beneficiario,
            SUM(#{cons2}.npersona) AS npersona
            FROM #{tablas3}
            #{twhere3}
            #{gb}"
    #puts "OJO q3 es #{q3}"
    @cuerpotabla = ActiveRecord::Base.connection.select_all(q3)

    @enctabla = []
    que3.each do |t|
      if (t[1] != "") 
        @enctabla << CGI.escapeHTML(t[1])
      end
    end

    respond_to do |format|
      format.html { }
      format.json { head :no_content }
      format.js   { render 'resultado' }
    end
  end


  def municipios
    authorize! :contar, Sivel2Gen::Caso
    #byebug
    @fechaini = '';
    cfecha = '';
    if (params[:fechaini] && params[:fechaini] != "") 
        pfechaini = DateTime.strptime(params[:fechaini], '%Y-%m-%d')
        @fechaini = pfechaini.strftime('%Y-%m-%d')
        cfecha += "fechaexpulsion >= '#{@fechaini}' AND "
    end
    @fechafin = '';
    if (params[:fechafin] && params[:fechafin] != "") 
        pfechafin = DateTime.strptime(params[:fechafin], '%Y-%m-%d')
        @fechafin = pfechafin.strftime('%Y-%m-%d')
        cfecha += "fechaexpulsion <= '#{@fechafin}' AND "
    end
 

    # expulsores
    @expulsores = ActiveRecord::Base.connection.select_all("
      SELECT (SELECT nombre FROM sivel2_gen_pais WHERE id=id_pais) AS pais, 
        (SELECT nombre FROM sivel2_gen_departamento
          WHERE id_pais=ubicacion.id_pais 
          AND id=id_departamento) AS departamento, 
        (SELECT nombre FROM sivel2_gen_municipio
          WHERE id_pais=ubicacion.id_pais 
          AND id_departamento=ubicacion.id_departamento 
          AND id=ubicacion.id_municipio) AS municipio, 
        COUNT(victima.id) AS cuenta
      FROM sivel2_sjr_desplazamiento AS desplazamiento, 
        sivel2_gen_ubicacion AS ubicacion, 
        sivel2_gen_victima AS victima
      WHERE 
        #{cfecha} 
        id_expulsion=ubicacion.id 
        AND desplazamiento.id_caso=victima.id_caso
      GROUP BY 1,2,3 ORDER BY 4 desc;
    ")
    # receptores
    @receptores = ActiveRecord::Base.connection.select_all("
      SELECT (SELECT nombre FROM sivel2_gen_pais WHERE id=id_pais) AS pais, 
        (SELECT nombre FROM sivel2_gen_departamento 
          WHERE id_pais=ubicacion.id_pais 
          AND id=id_departamento) AS departamento, 
        (SELECT nombre FROM sivel2_gen_municipio 
        WHERE id_pais=ubicacion.id_pais 
          AND id_departamento=ubicacion.id_departamento 
          AND id=ubicacion.id_municipio) AS municipio, 
        COUNT(victima.id) AS cuenta
      FROM sivel2_sjr_desplazamiento AS desplazamiento, 
        sivel2_gen_ubicacion AS ubicacion, 
        sivel2_gen_victima AS victima
      WHERE 
        #{cfecha} 
        id_llegada=ubicacion.id 
        AND desplazamiento.id_caso=victima.id_caso
      GROUP BY 1,2,3 ORDER BY 4 desc;
    ")
    respond_to do |format|
      format.html { }
      format.json { head :no_content }
      format.js   { }
    end
  end

  def rutas
    authorize! :contar, Sivel2Gen::Caso
    # Retorna cadena correspondiente al municipio de una ubicación
    ActiveRecord::Base.connection.select_all("
      CREATE OR REPLACE FUNCTION municipioubicacion(int) RETURNS varchar AS
      $$
        SELECT (SELECT nombre FROM sivel2_gen_pais WHERE id=ubicacion.id_pais) 
            || COALESCE((SELECT '/' || nombre FROM sivel2_gen_departamento 
            WHERE sivel2_gen_departamento.id_pais=ubicacion.id_pais 
            AND sivel2_gen_departamento.id=ubicacion.id_departamento),'') 
            || COALESCE((SELECT '/' || nombre FROM sivel2_gen_municipio 
            WHERE sivel2_gen_municipio.id_pais=ubicacion.id_pais 
            AND sivel2_gen_municipio.id_departamento=ubicacion.id_departamento 
            AND sivel2_gen_municipio.id=ubicacion.id_municipio),'') 
            FROM sivel2_gen_ubicacion AS ubicacion 
            WHERE ubicacion.id=$1;
      $$ 
      LANGUAGE SQL
    ");
    @rutas = ActiveRecord::Base.connection.select_all(
      "SELECT ruta, cuenta FROM ((SELECT municipioubicacion(d1.id_expulsion) || ' - ' 
        || municipioubicacion(d1.id_llegada) AS ruta, 
        count(id) AS cuenta
      FROM sivel2_sjr_desplazamiento AS d1
      GROUP BY 1)
      UNION  
      (SELECT municipioubicacion(d1.id_expulsion) || ' - ' 
        || municipioubicacion(d1.id_llegada) || ' - '
        || municipioubicacion(d2.id_llegada) AS ruta, 
        count(d1.id_caso) AS cuenta
      FROM sivel2_sjr_desplazamiento AS d1, 
        sivel2_gen_ubicacion AS l1, 
        sivel2_sjr_desplazamiento as d2,
        sivel2_gen_ubicacion AS e2, sivel2_gen_ubicacion AS l2
      WHERE 
      d1.id_caso=d2.id_caso
      AND d1.fechaexpulsion < d2.fechaexpulsion
      AND d1.id_llegada = l1.id
      AND d2.id_llegada = l2.id
      AND d2.id_expulsion = e2.id
      GROUP BY 1)) as sub
      ORDER BY 2 DESC
      "
    )
  end

  def desplazamientos
    authorize! :contar, Sivel2Gen::Caso
    if params[:ordenar] == 'Sexo'
        cord = "3, 6 DESC, 1"
    elsif params[:ordenar] == 'Edad'
        cord = "4, 6 DESC, 1"
    elsif params[:ordenar] == 'Sector'
        cord = "5, 6 DESC, 1"
    else
        cord = "6 DESC, 1"
    end
    @desplazamientos = ActiveRecord::Base.connection.select_all(
      "SELECT victima.id_caso, persona.id AS persona, 
        persona.sexo, rangoedad.rango as rangoedad,
        sectorsocial.nombre as sectorsocial,
        COUNT(desplazamiento.id) as cuenta
      FROM sivel2_gen_victima AS victima, 
        sivel2_gen_persona AS persona, 
        sivel2_sjr_desplazamiento AS desplazamiento, 
        sivel2_gen_rangoedad AS rangoedad, 
        sivel2_gen_sectorsocial AS sectorsocial
      WHERE victima.id_caso=desplazamiento.id_caso
        AND victima.id_persona=persona.id
        AND victima.id_rangoedad=rangoedad.id
        AND victima.id_sectorsocial=sectorsocial.id
      GROUP BY 1, 2, 3, 4, 5 ORDER BY #{cord};
      "
    )
  end
end
