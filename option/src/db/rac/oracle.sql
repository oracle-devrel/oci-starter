-- DROP TABLE scott.dept ;
CREATE TABLE scott.dept 
       (DEPTNO NUMBER PRIMARY KEY,
        DNAME VARCHAR2(64),
        LOC VARCHAR2(64) );

INSERT INTO scott.dept  VALUES (10, 'ACCOUNTING', 'NEW YORK');
INSERT INTO scott.dept  VALUES (20, 'RESEARCH',   'DALLAS');
INSERT INTO scott.dept  VALUES (30, 'SALES',      'CHICAGO');
INSERT INTO scott.dept  VALUES (40, 'OPERATIONS', 'BOSTON');
COMMIT;

CREATE TABLE CONTINUITY(
    COUNTER NUMBER, 
    NAME VARCHAR2(256), 
    CONNECT_STRING VARCHAR2(512), 
    INSTANCE VARCHAR2(256), 
    CREATION_TIME DATE
);

EXIT