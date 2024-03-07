**On this page:**

 - [Long identifiers in Babelfish](#long-identifiers-in-babelfish)
 - [Use of long and short names in queries](#use-of-long-and-short-names-in-queries)
 - [Column names in result set](#column-names-in-result-set)
 - [Converting between long and short names](#converting-between-long-and-short-names)

Long identifiers in Babelfish
-----------------------------

PostgreSQL has a maximum identifier length of 63 characters, while SQL Server supports up to 128. Common examples of long identifiers in SQL Server are column names.

Babelfish handles these restrictions by internally appending or replacing part of such identifiers with a 32-character string representing a hash of the identifier. While this is transparent from T-SQL, the identifier-with-hash is the object name when seen from PostgreSQL.

For example, if we create a table with overly long column name like this:

```sql
create table tab1 (
    id1 int,
    very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test nvarchar(max)
)
```

Actual column for this table will be created with the following short name:

```
very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
```

And the original long name will be stored in system catalog tables.

Use of long and short names in queries
--------------------------------------

Both long and short name can be used interchangeably in queries:

```sql
insert into tab1 (
	id1,
	very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test
) values(41, 'foo')
```
```sql
insert into tab1 (
	id1,
	very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
) values(42, 'bar')
```

Column names in result set
--------------------------

If either long or short name of a column is specified explicitly in `select`, then the short name will be returned in result set:

```sql
select 
    id1,
    very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test
from tab1
```

or

```sql
select 
    id1,
    very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
from tab1
```

give the same output:

```
id1         very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
----------- ---------------------------------------------------------------
41          foo
42          bar
```

Though, if `select *` is used, then the truncated version of the long name will be included in result set:

```sql
select * from tab1
```
```
id1         very_long_name_with_length_greater_than_63_but_less_equal_than_
----------- ---------------------------------------------------------------
41          foo
42          bar
```

Converting between long and short names
---------------------------------------

System function `babelfish_truncate_identifier` can be used to compute short name from a long one:

```sql
select sys.babelfish_truncate_identifier('very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test')
```
```
very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
```

The long name can be looked up in PostgreSQL system catalogs, for a column name we can use the following query (this example works on both TDS and PostgreSQL connections):

```sql
select split_part(array_to_string(trim_array(at.attoptions, array_length(at.attoptions, 1) - 1), ''), '=', 2)
from pg_class cl
join pg_attribute at
on cl.oid = at.attrelid
where cl.relname = 'tab1'
and at.attname = 'very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4'
```
```
very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test
```
