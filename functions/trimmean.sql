-- Copyright (c) 2023 Akira Miyakoda
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

--------------------------------------------------------------------------------
-- TRIMMEAN
--------------------------------------------------------------------------------

CREATE TYPE trimmean_stype AS (
    bucket     FLOAT [],
    proportion FLOAT
);

CREATE FUNCTION trimmean_sfunc(trimmean_stype, float, float)
RETURNS trimmean_stype AS $$
    SELECT ARRAY_APPEND($1.bucket, $2), $3;
$$ LANGUAGE SQL STRICT
IMMUTABLE;

CREATE FUNCTION trimmean_finalfunc(trimmean_stype)
RETURNS float AS $$
DECLARE
    trim_count INT;
    data_count INT;
    result     FLOAT;
BEGIN
    IF $1.proportion < 0 OR 1.0 <= $1.proportion THEN
        return NULL;
    END IF;

    data_count := ARRAY_LENGTH($1.bucket, 1);
    trim_count := FLOOR(data_count * $1.proportion) / 2;
    IF trim_count > 0 THEN
        data_count := data_count - trim_count * 2;
        SELECT AVG(v) INTO result FROM (SELECT v FROM UNNEST($1.bucket) AS v ORDER BY v OFFSET trim_count LIMIT data_count) AS x;
    ELSE
        SELECT AVG(v) INTO result FROM UNNEST($1.bucket) AS v;
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql STRICT
IMMUTABLE;

CREATE AGGREGATE trimmean(float, float)
(
    SFUNC = trimmean_sfunc,
    STYPE = trimmean_stype,
    FINALFUNC = trimmean_finalfunc,
    INITCOND = '({}, 0)'
);
