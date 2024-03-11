**On this page:**

 - [Long identifiers in PostgreSQL](#long-identifiers-in-postgresql)
 - [Long identifiers in Babelfish](#long-identifiers-in-babelfish)
 - [Use of long and short names in queries](#use-of-long-and-short-names-in-queries)
 - [Column names in result set](#column-names-in-result-set)
 - [Converting between long and short names](#converting-between-long-and-short-names)
 - [Indexes and constraint names](#index-and-constraint-names)

Long identifiers in PostgreSQL
------------------------------

Database engines impose limits on maximum length of user-specified identifiers like table names or column names. [SQL standard](https://en.wikipedia.org/wiki/ISO/IEC_9075) defines maximum identifier length as "an implementation-defined integer not less than 128".

While many other databases, including SQL Server, support identifiers up to 128 characters, PostgreSQL has a more strict limit. It is controlled by compile-time [NAMEDATALEN](https://pgpedia.info/n/NAMEDATALEN.html) variable. While in theory this limit can be set higher, this can cause higher memory usage and performance problems. In practice, virtually all PostgreSQL builds and extensions (including Babelfish) use `NAMEDATALEN` value of `64`. This effectively makes maximum identifier to be limited to 63 bytes (plus a trailing zero byte).

When PostgreSQL received identifier longer than `NAMEDATALEN - 1`, this identifier is truncated to 63 characters (here an below we assume that single-byte encoding is used). For example, if we create a table with a long column name like this (on PostgreSQL connection):

```sql
create table tab1 (
    id1 int,
    very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test text
)
```
```
NOTICE:  identifier "very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test" will be truncated to "very_long_name_with_length_greater_than_63_but_less_equal_than_"
CREATE TABLE
```

Both "long" and "truncated" names can be used inerchangebly in subsequent queries:

```sql
select very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test from tab1;
select very_long_name_with_length_greater_than_63_but_less_equal_than_ from tab1;
```

Long identifiers in Babelfish
-----------------------------

Being and extension to PostgreSQL, Babelfish cannot store identifiers longer than 63 characters. At the same time, to provide the compatibility with existing DB schemas coming from SQL Server, it needs to support input identifiers up to 128 characters.

Babelfish handles these problem by transforming incoming long identifiers into the "short" form. This is done by replacing part of such identifiers with a 32-character string representing a hash of the full identifier. Unlike the simple truncation, this method allows to handle multiple long column names which have the same first 63 characters.

While Babelfish handles this automatically in T-SQL, the identifier-with-hash is the object name that is actually stored and it can be seen only in this "short" form on PostgreSQL connection.

For example, if we create a table with overly long column name like this (on TDS connection):

```tsql
create table tab1 (
    id1 int,
    very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test nvarchar(max)
)
```

Actual column for this table will be created with the following short name:

```
very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
```

Original long name of the column will be stored in a system catalog table:

```tsql
select attoptions from pg_catalog.pg_attribute
where array_to_string(attoptions, '') like '%very_long_name_with_length_greater_than_63%'
```
```
attoptions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
{bbf_original_name=very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test}
```

Note that original names of other long identifiers (like table names), in general, are not preserved in system catalogs.

Use of long and short names in queries
--------------------------------------

Because incoming long name is shortened automatically, both long and short name can be used interchangeably in queries:

```tsql
insert into tab1 (
	id1,
	very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test
) values(41, 'foo')
```
```tsql
insert into tab1 (
	id1,
	very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
) values(42, 'bar')
```

Column names in result set
--------------------------

If either long or short name of a column is specified explicitly in `select` query, then the short name will be returned in result set metadata. Two following queries give the same output:

```tsql
select 
    id1,
    very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test
from tab1
```
```tsql
select 
    id1,
    very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
from tab1
```
```
id1         very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
----------- ---------------------------------------------------------------
41          foo
42          bar
```

Though, if `select *` is used, then the truncated "PostgreSQL native" version of the long name is included in result set metadata:

```tsql
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

For most types of idenifiers (with index and constraint names being the exception) system function `babelfish_truncate_identifier` can be used to compute short name from a long one:

```tsql
select sys.babelfish_truncate_identifier('very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test')
```
```
babelfish_truncate_identifier
------------------------------------------------------------------------------------------------------------------------------------------------------------
very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4
```

For column names the long form can be looked up in PostgreSQL system catalogs using the following query. Because column name is stored in PostgreSQL `ARRAY` column we need to use a number of functions to extract it. On PostgreSQL connection this can be simplified with array operators.

```tsql
select split_part(array_to_string(trim_array(at.attoptions, array_length(at.attoptions, 1) - 1), ''), '=', 2) as original_name
from pg_catalog.pg_class cl
join pg_catalog.pg_attribute at
on cl.oid = at.attrelid
where cl.relname = 'tab1'
and at.attname = 'very_long_name_with_length_greafcb500b635caaad2e5c26272eafc29e4'
```
```
original_name
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
very_long_name_with_length_greater_than_63_but_less_equal_than_128_that_we_would_like_to_test
```

Index and constraint names
--------------------------

Babelfish uses special handling for names of indexes and constraints even when these names do not exceed `NAMEDATALEN - 1` length limit.

In SQL Server the name of the index must be unique withing a table this index belongs to. Though, [in PostgreSQL](https://www.postgresql.org/docs/16/sql-createindex.html) "the name of the index must be distinct from the name of any other relation (table, sequence, index, view, materialized view, or foreign table) in that schema".

To handle this Babelfish transforms incoming index names into "unique" ones, appending the table name and a hash to it. For example, the following index:

```tsql
create index idx1 on tab1 (id1)
```

will be stored under `idx1tab1645826a2684a0937f93b08935f31319f` "unique" name and original index name will be discarded. In some cases (for short names) original index name can be extracted from "unique" name, for example this is done in `index_name` column in `sys.sp_statistics_view` view.

When the specified index name is longer than 63 characters, then the transformed "unique" name above also will appear longer than 63 characters and will be shortened-with-hash using the rules described in previous sections. Resulting "short" name won't contain the full original name.

Constraint names in PostgreSQL, in general, only require to be unique withing the table (or domain) they are defined on. But there is an exception for constraints that are implemented by an index (primary key, unique and exclusion constraints). In this case the index that implements the constraint must have the same name as the constraint itself. Because of this Babelfish handles names of all constraints the same way as index names.
