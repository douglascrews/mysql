-- General Utility & Administration

CREATE OR REPLACE VIEW processes_running
    AS
SELECT *
  FROM information_schema.processlist
 WHERE command != 'Sleep'
 ORDER BY time;

CREATE OR REPLACE VIEW process_list
    AS
SELECT id
     , user
     , host
     , db
     , command
     , time
     , state
     , info AS query
  FROM information_schema.processlist
 WHERE info LIKE '\^';

CREATE OR REPLACE VIEW table_sizes
    AS
SELECT table_schema
     , table_name
     , table_rows
     , ROUND((data_length + index_length) / 1024 / 1024 / 1024 / 1024, 2) AS size_tb
     , ROUND((data_length + index_length) / 1024 / 1024 / 1024, 2) AS size_gb
  FROM information_schema.tables
 ORDER BY size_tb DESC;

CREATE OR REPLACE VIEW scheduled_events
    AS
SELECT event_schema
     , event_name
     , status
     , last_executed
     , execute_at
     , CONCAT(interval_value, ' ', interval_field) AS event_interval
     , starts
     , ends
     , event_type
     , event_comment AS comment
     , on_completion
     , event_body
  FROM information_schema.events;

-- Foreign Keys

CREATE OR REPLACE VIEW all_fk
    AS
SELECT fks.constraint_name
     , CONCAT(fks.unique_constraint_schema, '.', fks.referenced_table_name) AS parent
     , CONCAT(fks.constraint_schema, '.', fks.table_name) AS child
     , GROUP_CONCAT(kcu.column_name ORDER BY POSITION_IN_UNIQUE_CONSTRAINT SEPARATOR ', ') AS fk_columns
     , fks.update_rule AS on_update
     , fks.delete_rule AS on_delete
  FROM information_schema.referential_constraints fks
  JOIN information_schema.key_column_usage kcu
    ON fks.constraint_schema = kcu.table_schema
   AND fks.table_name = kcu.table_name
   AND fks.constraint_name = kcu.constraint_name
 WHERE fks.referenced_table_name LIKE '\^'
 GROUP BY fks.constraint_schema
     , fks.table_name
     , fks.unique_constraint_schema
     , fks.referenced_table_name
     , fks.constraint_name
 ORDER BY fks.constraint_schema
     , fks.table_name;

-- Indexes

CREATE OR REPLACE VIEW dba_indexes
    AS
SELECT table_schema AS tab_schema
     , table_name AS tab_name
     , index_schema AS ndx_schema
     , index_name AS ndx_name
     , is_visible AS visible
     , index_type AS ndx_type
     , GROUP_CONCAT(CONCAT(column_name, IF(non_unique, CONCAT(' [', cardinality, ']'), ' [U]')) ORDER BY seq_in_index SEPARATOR ', ') AS ndx_columns
  FROM information_schema.statistics
 GROUP BY table_schema
     , table_name
     , index_schema
     , index_name
     , is_visible
     , index_type;

CREATE OR REPLACE VIEW all_indexes
    AS
SELECT *
  FROM dba_indexes
 WHERE tab_schema NOT IN 
     ( 'information_schema'
     , 'mysql'
     , 'performance_schema'
     , 'sys'
     )
   AND ndx_schema NOT IN 
     ( 'information_schema'
     , 'mysql'
     , 'performance_schema'
     , 'sys'
     );

CREATE OR REPLACE VIEW user_indexes
    AS
SELECT *
  FROM all_indexes
 WHERE tab_schema = CURRENT_USER()
    OR ndx_schema = CURRENT_USER();

CREATE OR REPLACE VIEW unused_indexes
    AS
SELECT * 
  FROM sys.schema_unused_indexes 
 WHERE index_name NOT LIKE '\^fk_%'
   AND object_schema NOT IN ('performance_schema', 'mysql' ,'information_schema');

-- Tables

CREATE OR REPLACE VIEW dba_tables
    AS
SELECT table_catalog AS tab_catalog
     , table_schema AS tab_schema
     , table_name AS tab_name
     , table_type AS tab_type
     , engine
     , version
     , row_format
     , table_rows AS row_count
--     , avg_row_length
--     , data_length
--     , max_data_length
--     , index_length
--     , data_free
--     , auto_increment
--     , create_time AS created_tstamp
--     , update_time AS updated_tstamp
--     , check_time
--     , table_collation
--     , checksum
--     , create_options
     , table_comment AS comment
  FROM information_schema.tables
 WHERE table_type = 'BASE TABLE';

CREATE OR REPLACE VIEW all_tables
    AS
SELECT *
  FROM dba_tables
 WHERE tab_schema NOT IN
     ( 'information_schema'
     , 'mysql'
     , 'performance_schema'
     , 'sys'
     );

CREATE OR REPLACE VIEW user_tables
    AS
SELECT *
  FROM all_tables
 WHERE tab_schema = CURRENT_USER();

CREATE OR REPLACE VIEW dba_tab_columns
    AS
SELECT table_catalog AS tab_catalog
     , table_schema AS tab_schema
     , table_name AS tab_name
     , column_name AS col_name
     , ordinal_position AS ordinal
--     , data_type
     , CONCAT(column_type, IFNULL(numeric_precision,'')) AS col_type
     , column_key AS col_key
     , column_default AS col_default
     , CASE 
          WHEN is_nullable = 'YES' then 'NO'
          ELSE 'YES'
       END 
       AS required
--     , character_maximum_length
--     , character_octet_length
--     , column_type
--     , numeric_precision
--     , numeric_scale
--     , datetime_precision
--     , character_set_name
--     , collation_name
--     , extra
     , privileges
     , column_comment AS comment
--     , generation_expression
--     , srs_id
  FROM information_schema.columns
 WHERE (table_catalog, table_schema, table_name) IN 
     ( SELECT table_catalog, table_schema, table_name
         FROM information_schema.tables
        WHERE table_type = 'BASE TABLE'
     );

CREATE OR REPLACE VIEW all_tab_columns
    AS
SELECT *
  FROM dba_tab_columns
 WHERE tab_schema NOT IN
     ( 'information_schema'
     , 'mysql'
     , 'performance_schema'
     , 'sys'
     );

CREATE OR REPLACE VIEW user_tab_columns
    AS
SELECT *
  FROM all_tab_columns
 WHERE tab_schema = CURRENT_USER();

-- Views

CREATE OR REPLACE VIEW dba_views
    AS
SELECT table_catalog AS tab_catalog
     , table_schema AS tab_schema
     , table_name AS tab_name
     , table_type AS tab_type
     , engine
     , version
     , row_format
     , table_rows AS row_count
--     , avg_row_length
--     , data_length
--     , max_data_length
--     , index_length
--     , data_free
--     , auto_increment
--     , create_time AS created_tstamp
--     , update_time AS updated_tstamp
--     , check_time
--     , table_collation
--     , checksum
--     , create_options
     , table_comment AS comment
  FROM information_schema.tables
 WHERE table_type = 'VIEW';

CREATE OR REPLACE VIEW all_views
    AS
SELECT *
  FROM dba_views
 WHERE tab_schema NOT IN
     ( 'information_schema'
     , 'mysql'
     , 'performance_schema'
     , 'sys'
     );

CREATE OR REPLACE VIEW dba_view_columns
    AS
SELECT table_catalog AS tab_catalog
     , table_schema AS tab_schema
     , table_name AS tab_name
     , column_name AS col_name
     , ordinal_position AS ordinal
--     , data_type
     , CONCAT(column_type, IFNULL(numeric_precision,'')) AS col_type
     , column_key AS col_key
     , column_default AS col_default
     , CASE 
          WHEN is_nullable = 'YES' then 'NO'
          ELSE 'YES'
       END 
       AS required
--     , character_maximum_length
--     , character_octet_length
--     , column_type
--     , numeric_precision
--     , numeric_scale
--     , datetime_precision
--     , character_set_name
--     , collation_name
--     , extra
     , privileges
     , column_comment AS comment
--     , generation_expression
--     , srs_id
  FROM information_schema.columns
 WHERE (table_catalog, table_schema, table_name) IN 
     ( SELECT table_catalog, table_schema, table_name
         FROM information_schema.tables
        WHERE table_type = 'VIEW'
     );

CREATE OR REPLACE VIEW user_view_columns
    AS
SELECT *
  FROM all_views
 WHERE tab_schema = CURRENT_USER();
CREATE OR REPLACE VIEW all_view_columns
    AS
SELECT *
  FROM dba_view_columns
 WHERE tab_schema NOT IN
     ( 'information_schema'
     , 'mysql'
     , 'performance_schema'
     , 'sys'
     );

CREATE OR REPLACE VIEW user_view_columns
    AS
SELECT *
  FROM all_view_columns
 WHERE tab_schema = CURRENT_USER();
