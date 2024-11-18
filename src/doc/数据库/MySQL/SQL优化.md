# SQL优化

```pgsql

SELECT FEE_TYPE,SUM(${@com.kingtsoft.kingpower.frame.utils.core.DBUtil@getNull()}(AMOUNT,0)) AMOUNT
        FROM
        (
        SELECT AMOUNT,
        (SELECT CASE WHEN NAME LIKE '%体检%' OR NAME LIKE '%磁共振%' OR NAME LIKE '%CT%'OR NAME LIKE '%放射%'OR NAME LIKE '%检查%' THEN '05'
        WHEN NAME LIKE '%治疗%' THEN '06'
        WHEN NAME LIKE '%手术%' THEN '07'
        WHEN NAME LIKE '%检验%' THEN '08'
        WHEN NAME LIKE '%材料%' THEN '09'
        ELSE '99'END FROM ACC_DIC_FEE_CLASSIFY WHERE ID = B.CLASSIFY_ID) FEE_TYPE
         FROM OIS_BILL_DETAILS A,ACC_DIC_FEE_ITEM B
        WHERE A.FEE_ID = B.ID
        AND A.BILL_ID IN (SELECT BILL_ID FROM OIS_BILL WHERE OPC_ID = #{opcId} AND INVALID_TIME IS NULL)
        AND A.HT = 'C'
        union all
        SELECT AMOUNT,
        (CASE WHEN b.TYPE ='Y' THEN '01'
        WHEN b.TYPE = 'Z' THEN '02'
        WHEN b.TYPE = 'C' THEN '03'
        ELSE '99' END) FEE_TYPE
        FROM OIS_BILL_DETAILS A,MMIS_DIC_MED B
        WHERE A.Mat_Id = B.ID
        AND B.TYPE IN ('Y', 'Z', 'C')
        AND A.BILL_ID IN (SELECT BILL_ID FROM OIS_BILL WHERE OPC_ID = #{opcId} AND INVALID_TIME IS NULL)
        AND A.HT = 'C'
        union all
        SELECT SUM(${@com.kingtsoft.kingpower.frame.utils.core.DBUtil@getNull()}(AMOUNT,0)) AMOUNT,'00' FEE_TYPE
        FROM OIS_BILL_DETAILS A
        WHERE A.BILL_ID IN (SELECT BILL_ID FROM OIS_BILL WHERE OPC_ID = #{opcId} AND INVALID_TIME IS NULL)
        AND A.HT = 'C'
        ) T
        GROUP BY FEE_TYPE
```

在子查询结果集上进行操作的查询是外部查询。

一些不认识的函数：

```pgsql
COALESCE 函数是一个在 SQL 中用于处理空值的函数，它的语法如下：
COALESCE ( expression_1, expression_2,..., expression_n )
COALESCE 函数会依次检查每个表达式的值，并返回第一个非空的值。如果所有的表达式都为空值，则返回 NULL。
以下是一个使用 COALESCE 函数的示例：
假设有一个名为 employees 的表，其中包含 name、salary 和 bonus 三个列。如果 bonus 列的值为 NULL，我们希望使用 0 来代替。可以使用以下查询来实现：
SELECT name, salary, COALESCE(bonus, 0) AS bonus FROM employees;
在这个查询中，COALESCE 函数会检查 bonus 列的值。如果 bonus 列的值不为 NULL，它将返回该值；否则，它将返回 0。
```

```pgsql
在 SQL 中，EXTRACT()是一个用于从日期时间值中提取特定部分（如年、月、日、小时等）的函数。
其语法通常为：EXTRACT(unit FROM datetime_expression)。
其中，unit是要提取的时间部分，可以是YEAR（年）、MONTH（月）、DAY（日）、HOUR（小时）、MINUTE（分钟）、SECOND（秒）等；datetime_expression是一个日期时间类型的表达式，可以是一个日期时间列、一个函数返回的日期时间值或一个常量日期时间值。
例如：
sql
复制
SELECT EXTRACT(YEAR FROM '2023-10-29'::date) AS year_value;
-- 返回结果为 2023
这个函数在处理日期时间数据时非常有用，可以方便地获取特定的时间部分进行分析或计算。不同的数据库系统可能对EXTRACT()函数的支持略有不同，但基本用法相似。
```

什么是外部查询：

> 在 SQL 中，聚合函数是对一组值进行计算并返回单一值的函数。当聚合函数出现在查询的 SELECT 子句中，且不是在子查询中时，就称为外部聚合函数。外部聚合函数用于对整个查询结果集进行聚合操作。

区分外查询和子查询：

* **查询每个部门的平均薪资** ：

```sql
SELECT department_id, 
       (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id) AS average_salary
FROM employees e
GROUP BY department_id;
```

* **查询每个班级的学生人数** ：

```sql
SELECT class_id, 
       (SELECT COUNT(*) FROM students WHERE class_id = s.class_id) AS student_count
FROM students s
GROUP BY class_id;
```

* **查询每个城市的订单总金额** ：

```sql
SELECT city, 
       (SELECT SUM(amount) FROM orders WHERE city = o.city) AS total_amount
FROM orders o
GROUP BY city;
```

* **查询每个产品类别的最高价格** ：

```sql
SELECT category_id, 
       (SELECT MAX(price) FROM products WHERE category_id = p.category_id) AS max_price
FROM products p
GROUP BY category_id;
```

* **查询每个供应商的最低价格** ：

```sql
SELECT supplier_id, 
       (SELECT MIN(price) FROM products WHERE supplier_id = s.supplier_id) AS min_price
FROM products s
GROUP BY supplier_id;
```

#### 覆盖索引

概念：一种在数据库中用于优化查询性能的索引结构，它与普通索引有所不同

* 覆盖索引是指一个索引包含了（或覆盖了）满足查询语句中所需的所有字段，而不需要再去访问数据表中的原始数据行。也就是说，当查询的列都可以从索引中直接获取时，就无需回表查询数据行，从而提高查询效率。

**优点**

* **提高查询性能** ：由于避免了回表操作，减少了数据的读取量和 I/O 操作，因此可以显著提高查询的速度，尤其是在处理大量数据时效果更为明显。
* **减少磁盘 I/O** ：因为不需要从磁盘读取完整的数据行，只需要读取索引中的数据，所以减少了磁盘 I/O 的开销，提高了系统的整体性能。
* **降低数据库负载** ：覆盖索引可以减少数据库服务器的负载，因为它需要处理的数据量更少，从而可以提高数据库的并发处理能力。

**缺点**

* **索引占用空间大** ：由于覆盖索引包含了更多的列，因此它占用的磁盘空间通常会比普通索引大。
* **维护成本高** ：当数据表中的数据发生变化时，覆盖索引也需要进行相应的更新，这可能会增加维护索引的成本。

覆盖索引是一个大类，他的名下具有很多别的索引，例如（たどえば）

* **联合索引** ：如果为表中的多个字段创建了联合索引，并且查询语句中只需要获取这些索引字段的值，那么这个联合索引就是覆盖索引。例如，为 `employees`表的 `name`、`age`和 `department`字段创建了联合索引 `idx_name_age_department`，当执行查询语句 `SELECT name, age, department FROM employees WHERE age > 30`时，这个联合索引就是覆盖索引，因为查询所需的列都包含在索引中，无需回表查询数据行。
* **包含索引** ：某些数据库支持创建包含索引，即索引中不仅包含索引键列，还可以包含其他非索引键列。如果查询语句中需要获取的列都包含在这个包含索引中，那么它就是覆盖索引。例如，在 `employees`表中创建了一个包含索引 `idx_name_age_include_salary`，其中包含了 `name`、`age`和 `salary`字段。当执行查询语句 `SELECT name, age, salary FROM employees WHERE age > 30`时，这个包含索引就是覆盖索引。
* **普通索引** ：单个字段的普通索引也可以成为覆盖索引。例如，为 `employees`表的 `id`字段创建了普通索引 `idx_id`，当执行查询语句 `SELECT id FROM employees WHERE id = 1001`时，这个普通索引就是覆盖索引。

要确定一个索引是否为覆盖索引，关键是看查询语句中需要获取的列是否都能够从该索引中直接获取，而无需再去访问数据表中的原始数据行。如果是，那么这个索引就是覆盖索引。

#### 普通索引
