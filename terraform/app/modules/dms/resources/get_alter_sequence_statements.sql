CREATE OR REPLACE FUNCTION export_sequence_adjustments()
    RETURNS TABLE (create_sequence TEXT) AS $$
DECLARE
    rec RECORD;
    query TEXT;
    has_rows BOOLEAN;
    sequence_buffer INTEGER := 10000;
BEGIN
    -- Create a temporary table to store results
    CREATE TEMPORARY TABLE temp_results (create_sequence TEXT);

    -- Loop through tables with matching sequences and an 'id' column, including the data type
    FOR rec IN (
        SELECT t.table_name, s.sequence_name, c.data_type
        FROM information_schema.sequences s
            JOIN information_schema.tables t
              ON t.table_schema = 'public'
                  AND s.sequence_name LIKE LOWER(t.table_name) || '%'
            JOIN information_schema.columns c
              ON c.table_schema = t.table_schema
                  AND c.table_name = t.table_name
                  AND c.column_name = 'id'
                  AND c.data_type IN ('integer', 'bigint', 'numeric')
    ) LOOP
            -- Check if the table has any rows
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I LIMIT 1)', rec.table_name) INTO has_rows;

            -- If the table has rows and 'id' is bigint, use max(id) + 10000
            IF has_rows THEN
                query := format(
                    'INSERT INTO temp_results (create_sequence) SELECT ''ALTER SEQUENCE %I RESTART WITH '' || (id + %s)::text || '';'' FROM public.%I ORDER BY id DESC LIMIT 1',
                    rec.sequence_name, sequence_buffer, rec.table_name
                );
                EXECUTE query;
                -- For empty tables use default START WITH 10000
            ELSE
                query := format(
                    'INSERT INTO temp_results (create_sequence) VALUES (''ALTER SEQUENCE %I RESTART WITH %s;'')',
                    rec.sequence_name, sequence_buffer
                );
                EXECUTE query;
            END IF;
        END LOOP;

    -- Return all results
    RETURN QUERY SELECT * FROM temp_results;

    -- Clean up
    DROP TABLE temp_results;
END;
$$ LANGUAGE plpgsql;

-- Run the function
SELECT * FROM export_sequence_adjustments();
DROP FUNCTION export_sequence_adjustments();
