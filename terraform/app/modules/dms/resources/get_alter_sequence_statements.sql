CREATE OR REPLACE FUNCTION export_sequence_adjustments()
    RETURNS TABLE
            (
                alter_sequence TEXT
            )
AS
$$
DECLARE
    rec             RECORD;
    query           TEXT;
    sequence_buffer INTEGER := 10000;
BEGIN
    CREATE TEMPORARY TABLE temp_results
    (
        alter_sequence TEXT
    );

    FOR rec IN (SELECT s.sequence_name FROM information_schema.sequences s where s.sequence_schema = 'public')
        LOOP
            query := format(
                    'INSERT INTO temp_results (alter_sequence) SELECT ''ALTER SEQUENCE %I RESTART WITH '' || (id + %s)::text || '';'' FROM (SELECT last_value as id from public.%I)',
                    rec.sequence_name, sequence_buffer, rec.sequence_name
                     );
            EXECUTE query;
        END LOOP;

    RETURN QUERY SELECT * FROM temp_results;
    DROP TABLE temp_results;
END;
$$ LANGUAGE plpgsql;

SELECT *
FROM export_sequence_adjustments();
DROP FUNCTION export_sequence_adjustments();
