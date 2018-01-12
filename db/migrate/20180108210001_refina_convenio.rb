class RefinaConvenio < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      DELETE FROM tipoconvenio WHERE id IN (28, 27, 26, 25, 24, 23, 21, 14, 10, 9, 6, 2);
    SQL
  end

  def down
    execute <<-SQL
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (2, 'ACUERDO ', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (6, 'CONSULTORIA ', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (9, 'CONTRATO DE CONSULTORIA ', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (10, 'CONTRATO DE PRESTACIÓN DE SERVICIOS', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (14, 'CONVENIO DE COOPERACIÓN INTERINSTITUCIONAL ', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (21, 'CONVENIO INTERINSTITUCIONAL ', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (23, 'CONVENIO MARCO DE COOPERACIÓN INTERINSTITUCIONAL', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (24, 'CONVENIO MARCO INTERINSTITUCIONAL', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (25, 'CONVENIO PARA EL USO DEL GIMNASIO ', '2017-08-16', '2017-08-16', '2017-08-16');
      
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (26, 'EXTERIORES DE LA UNIÓN EUROPEA  – EIDHR/2015/371 – 341. PROGRAMA TIERRA Y SEMILLA', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (27, 'MEMORANDUM OF UNDERSTANDING', '2017-08-16', '2017-08-16', '2017-08-16');
      INSERT INTO TIPOCONVENIO (ID, NOMBRE, FECHACREACION, CREATED_AT, UPDATED_AT) VALUES (28, 'MIEMBRO DE LA JUNTA DIRECTIVA', '2017-08-16', '2017-08-16', '2017-08-16');
    SQL
  end
end
