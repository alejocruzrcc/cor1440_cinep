class AjustaRepUsuario < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      -- Ya había listado
      DELETE FROM heb412_gen_campoplantillahcm WHERE plantillahcm_id=10;
      DELETE FROM heb412_gen_plantillahcm WHERE id=10;

      UPDATE heb412_gen_plantillahcr 
        SET ruta='Gestion Humana/reporte_usuario.ods' WHERE id=10;
      UPDATE heb412_gen_plantilladoc
        SET ruta='Gestion Humana/reporte_usuario.odt' WHERE id=10;

      UPDATE heb412_gen_campoplantillahcr SET nombrecampo='presenta_nombre'
        WHERE plantillahcr_id=10 AND id='322';
      DELETE FROM heb412_gen_campoplantillahcr 
        WHERE plantillahcr_id=10 AND id='323';
    SQL
  end
end
