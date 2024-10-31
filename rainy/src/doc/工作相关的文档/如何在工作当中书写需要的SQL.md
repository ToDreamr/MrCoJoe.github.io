# 书写SQL

#### 常用的函数：

##### IFNULL（expression,default value）只适用于MySQL

在 SQL 中，`IFNULL`是一个函数，用于判断一个表达式是否为 `NULL`，如果为 `NULL`则返回指定的值，否则返回表达式本身的值。其语法格式为：`IFNULL(expression, value_if_null)`。

以下是对 `IFNULL`函数的详细解释：

* **参数说明**
  * **expression** ：必需参数，要检查是否为 `NULL`的表达式。
  * **value_if_null** ：必需参数，如果 `expression`为 `NULL`，则返回此值。
* **返回值**
  * 如果 `expression`的值不为 `NULL`，则 `IFNULL`函数返回 `expression`的值。
  * 如果 `expression`的值为 `NULL`，则 `IFNULL`函数返回 `value_if_null`的值。
* **示例**
  * 假设有一个名为 `employees`的表，其中包含 `name`和 `salary`两列。如果要查询员工的工资，如果工资为 `NULL`，则显示 `0`，可以使用以下查询语句：`SELECT name, IFNULL(salary, 0) AS salary FROM employees;`

`IFNULL`函数在处理可能包含 `NULL`值的数据时非常有用，可以避免因为 `NULL`值导致的错误或异常。

##### NVL `(expression1, expression2)`

Oracle 中有与 `IFNULL`函数类似的函数，即 `NVL`函数。

`NVL`函数的语法格式为：`NVL(expression1, expression2)`。

该函数的作用是判断 `expression1`是否为 `NULL`，如果是 `NULL`，则返回 `expression2`的值，否则返回 `expression1`的值。

##### 如何使用Case When 语句？

`CASE WHEN`语句是一种条件表达式，它允许根据条件返回不同的值

模板语法：

```sql
CASE 
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
   ...
    ELSE result
END
```

使用 `CASE WHEN`语句来模拟 `IFNULL`函数的示例：

```sql
SELECT 
    column1,
    -- 使用CASE WHEN语句模拟IFNULL函数
    CASE WHEN column1 IS NULL THEN value_if_null ELSE column1 END AS new_column
FROM 
    table_name;
```
