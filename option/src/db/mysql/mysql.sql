-- DROP DATABASE db1;
show databases;
create database db1;
use db1;

-- DROP TABLE dept ;
create table dept 
       (deptno integer primary key,
        dname varchar(64),
        loc varchar(64) );

INSERT INTO dept values (10, 'ACCOUNTING', 'BRUSSELS');
INSERT INTO dept values (20, 'RESEARCH',   'MYSQL');
INSERT INTO dept values (30, 'SALES',      'ROME');
INSERT INTO dept values (40, 'OPERATIONS', 'MADRID');
select deptno, dname, loc FROM dept;


