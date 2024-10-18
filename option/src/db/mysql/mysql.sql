-- DROP DATABASE db1;
show databases;
create database db1;
use db1;

-- DROP TABLE scott.dept ;
create table scott.dept 
       (deptno integer primary key,
        dname varchar(64),
        loc varchar(64) );

insert into scott.dept  values (10, 'ACCOUNTING', 'BRUSSELS');
insert into scott.dept  values (20, 'RESEARCH',   'MYSQL');
insert into scott.dept  values (30, 'SALES',      'ROME');
insert into scott.dept  values (40, 'OPERATIONS', 'MADRID');
select scott.dept no, dname, loc from scott.dept ;


