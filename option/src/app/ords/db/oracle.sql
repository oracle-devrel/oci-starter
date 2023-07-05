-- XXXX This is a very bad practice to use the ADMIN user.
-- XXXX Should create a user scott and replace connect string with SCOTT ?
-- DROP TABLE DEPT;
CREATE TABLE DEPT
       (DEPTNO NUMBER PRIMARY KEY,
        DNAME VARCHAR2(64),
        LOC VARCHAR2(64) );

INSERT INTO DEPT VALUES (10, 'ACCOUNTING', 'NEW YORK');
INSERT INTO DEPT VALUES (20, 'RESEARCH',   'DALLAS');
INSERT INTO DEPT VALUES (30, 'SALES',      'CHICAGO');
INSERT INTO DEPT VALUES (40, 'OPERATIONS', 'BOSTON');
COMMIT;

BEGIN
  ORDS.enable_schema(
    p_enabled             => TRUE,
    p_schema              => 'ADMIN',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'starter',
    p_auto_rest_auth      => FALSE
  );  
  COMMIT;
END;
/
BEGIN
  ORDS.define_module(
    p_module_name    => 'module',
    p_base_path      => 'module/',
    p_items_per_page => 0);

  ORDS.define_template(
   p_module_name    => 'module',
   p_pattern        => 'dept');    
  
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'module',
      p_pattern        => 'dept',
      p_method         => 'GET',
      p_source_type    => 'resource/lob',
      p_items_per_page =>  0,
      p_mimes_allowed  => '',
      p_comments       => NULL,
      p_source         =>  'select ''application/json'', json_arrayagg( json_object(deptno, dname, loc) ) FROM dept'
  );

  ORDS.define_template(
   p_module_name    => 'module',
   p_pattern        => 'info');

  -- XXX pn_status needed ??
  ORDS.define_handler(
    p_module_name    => 'module',
    p_pattern        => 'info',
    p_method         => 'GET',
    p_source_type    => ords.source_type_plsql,
    p_source         => 'BEGIN
                           :pn_status := 200;
                           HTP.print(''ORDS'');
                        END;
                        ');
  commit;                      
end;                        
/

EXIT
-- GET http://ords_url/ords/starter/module/dept
-- GET http://ords_url/ords/starter/module/info