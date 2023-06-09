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

CREATE TABLE CONTINUITY(
    COUNTER NUMBER, 
    NAME VARCHAR2(256), 
    CONNECT_STRING VARCHAR2(512), 
    INSTANCE VARCHAR2(256), 
    CREATION_TIME DATE
);

EXIT