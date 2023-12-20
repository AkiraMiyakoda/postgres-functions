-- Copyright (c) 2023 Akira Miyakoda
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

--------------------------------------------------------------------------------
-- UUID_GENERATE_V7
--------------------------------------------------------------------------------

-- Based on IETF draft, https://datatracker.ietf.org/doc/draft-ietf-uuidrev-rfc4122bis/

--  0                   1                   2                   3
--  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |                           unix_ts_ms                          |
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |          unix_ts_ms           |  ver  |       rand_a          |
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |var|                        rand_b                             |
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |                            rand_b                             |
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

CREATE FUNCTION uuid_generate_v7()
RETURNS UUID
AS $$
DECLARE
    unix_ts_ms BYTEA;
    uuid_bytes BYTEA;
BEGIN
    unix_ts_ms = SUBSTRING(INT8SEND(FLOOR(EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) * 1000)::BIGINT) FROM 3);

    -- Use random v4 uuid as starting point (which has the same variant we need)
    uuid_bytes = UUID_SEND(GEN_RANDOM_UUID());

    -- overlay timestamp
    uuid_bytes = OVERLAY(uuid_bytes PLACING unix_ts_ms FROM 1 FOR 6);

    -- Set version 7
    uuid_bytes = SET_BYTE(uuid_bytes, 6, (B'0111' || GET_BYTE(uuid_bytes, 6)::BIT(4))::BIT(8)::INT);

    RETURN ENCODE(uuid_bytes, 'HEX')::UUID;
END
$$ LANGUAGE plpgsql
VOLATILE;
