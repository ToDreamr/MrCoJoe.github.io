# Oracle

建表语句：

```sql

create table DEPARTMENTS (  
  deptno        number,  
  name          varchar2(50) not null,  
  location      varchar2(50),  
  constraint pk_departments primary key (deptno)  
);

```

Tables can declarative specify relationships between tables, typically referred to as referential integrity. To see how this works we can create a "child" table of the DEPARTMENTS table by including a foreign key in the EMPLOYEES table that references the DEPARTMENTS table. For example:

```sql

create table EMPLOYEES (  
  empno             number,  
  name              varchar2(50) not null,  
  job               varchar2(50),  
  manager           number,  
  hiredate          date,  
  salary            number(7,2),  
  commission        number(7,2),  
  deptno           number,  
  constraint pk_employees primary key (empno),  
  constraint fk_employees_deptno foreign key (deptno) 
      references DEPARTMENTS (deptno)  
);

```

触发器：

Triggers are procedures that are stored in the database and are implicitly run, or fired, when something happens. Traditionally, triggers supported the execution of a procedural code, in Oracle procedural SQL is called a PL/SQL block. PL stands for procedural language. When an INSERT, UPDATE, or DELETE occurred on a table or view. Triggers support system and other data events on DATABASE and SCHEMA.

Triggers are frequently used to automatically populate table primary keys, the trigger examples below show an example trigger to do just this. We will use a built in function to obtain a globallally unique identifier or GUID.

创建触发器：

```sql

create or replace trigger  DEPARTMENTS_BIU
    before insert or update on DEPARTMENTS
    for each row
begin
    if inserting and :new.deptno is null then
        :new.deptno := to_number(sys_guid(), 
          'Do something');
    end if;
end;
/

create or replace trigger EMPLOYEES_BIU
    before insert or update on EMPLOYEES
    for each row
begin
    if inserting and :new.empno is null then
        :new.empno := to_number(sys_guid(), 
            'Do something');
    end if;
end;
/

```

Now that we have tables created, and we have triggers to automatically populate our primary keys, we can add data to our tables. Because we have a parent child relationship, with the DEPARTMENTS table as the parent table, and the EMPLOYEES table as the child we will first INSERT a row into the DEPARTMENTS table.

```sql
select * from departments;
```

use the sentence above to select your data.

You can see that an ID will have been automatically generated. You can now insert into the EMPLOYEES table a new row but you will need to put the generated DEPTID value into your SQL INSERT statement. The examples below show how we can do this using a SQL query, but you could simply enter the department number directly.

```sql

insert into EMPLOYEES 
   (name, job, salary, deptno) 
   values
   ('Sam Smith','Programmer', 
    5000, 
  (select deptno 
  from departments 
  where name = 'Development'));

insert into EMPLOYEES 
   (name, job, salary, deptno) 
   values
   ('Mara Martin','Analyst', 
   6000, 
   (select deptno 
   from departments 
   where name = 'Finance'));

insert into EMPLOYEES 
   (name, job, salary, deptno) 
   values
   ('Yun Yates','Analyst', 
   5500, 
   (select deptno 
   from departments 
   where name = 'Development'));
```

## Indexing Columns

Typically developers index columns for three major reasons:

1. To enforce unique values within a column
2. To improve data access performance
3. To prevent lock escalation when updating rows of tables that use declarative referential integrity

> When a table is created and a PRIMARY KEY is specified an index is automatically created to enforce the primary key constraint. If you specific UNIQUE for a column when creating a column a unique index is also created. To see the indexes that already exist for a given table you can run the following dictionary query.

```sql

select table_name "Table", 
       index_name "Index", 
       column_name "Column", 
       column_position "Position"
from  user_ind_columns 
where table_name = 'EMPLOYEES' or 
      table_name = 'DEPARTMENTS'
order by table_name, column_name, column_position
```

use a foreign key:

```
create index employee_dept_no_fk_idx 
on employees (deptno)
```

when select some other data with oracle function like below:

You can sum data in tables using aggregate functions. We will use column aliases to rename columns for readability, we will also use the null value function (NVL) to allow us to properly sum columns with null values.

```

select 
      count(*) employee_count,
      sum(salary) total_salary,
      sum(commission) total_commission,
      min(salary + nvl(commission,0)) min_compensation,
      max(salary + nvl(commission,0)) max_compensation
from employees;

```
