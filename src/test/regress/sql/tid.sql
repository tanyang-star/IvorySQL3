-- basic tests for the TID data type

SELECT
  '(0,0)'::tid as tid00,
  '(0,1)'::tid as tid01,
  '(-1,0)'::tid as tidm10,
  '(4294967295,65535)'::tid as tidmax;

SELECT '(4294967296,1)'::tid;  -- error
SELECT '(1,65536)'::tid;  -- error

-- Also try it with non-error-throwing API
SELECT pg_input_is_valid('(0)', 'tid');
SELECT * FROM pg_input_error_info('(0)', 'tid');
SELECT pg_input_is_valid('(0,-1)', 'tid');
SELECT * FROM pg_input_error_info('(0,-1)', 'tid');


-- tests for functions related to TID handling

CREATE TABLE tid_tab (a int);

-- min() and max() for TIDs
INSERT INTO tid_tab VALUES (1), (2);
SELECT min(ctid) FROM tid_tab;
SELECT max(ctid) FROM tid_tab;
TRUNCATE tid_tab;

-- Tests for currtid2() with various relation kinds

-- Materialized view
CREATE MATERIALIZED VIEW tid_matview AS SELECT a FROM tid_tab;
SELECT currtid2('tid_matview'::text, '(0,1)'::tid); -- fails
INSERT INTO tid_tab VALUES (1);
REFRESH MATERIALIZED VIEW tid_matview;
SELECT currtid2('tid_matview'::text, '(0,1)'::tid); -- ok
DROP MATERIALIZED VIEW tid_matview;
TRUNCATE tid_tab;

-- Sequence
CREATE SEQUENCE tid_seq;
SELECT currtid2('tid_seq'::text, '(0,1)'::tid); -- ok
DROP SEQUENCE tid_seq;

-- Index, fails with incorrect relation type
CREATE INDEX tid_ind ON tid_tab(a);
SELECT currtid2('tid_ind'::text, '(0,1)'::tid); -- fails
DROP INDEX tid_ind;

-- Partitioned table, no storage
CREATE TABLE tid_part (a int) PARTITION BY RANGE (a);
SELECT currtid2('tid_part'::text, '(0,1)'::tid); -- fails
DROP TABLE tid_part;

-- Views
-- ctid not defined in the view
CREATE VIEW tid_view_no_ctid AS SELECT a FROM tid_tab;
SELECT currtid2('tid_view_no_ctid'::text, '(0,1)'::tid); -- fails
DROP VIEW tid_view_no_ctid;
-- ctid fetched directly from the source table.
CREATE VIEW tid_view_with_ctid AS SELECT ctid, a FROM tid_tab;
SELECT currtid2('tid_view_with_ctid'::text, '(0,1)'::tid); -- fails
INSERT INTO tid_tab VALUES (1);
SELECT currtid2('tid_view_with_ctid'::text, '(0,1)'::tid); -- ok
DROP VIEW tid_view_with_ctid;
TRUNCATE tid_tab;
-- ctid attribute with incorrect data type
CREATE VIEW tid_view_fake_ctid AS SELECT 1 AS ctid, 2 AS a;
SELECT currtid2('tid_view_fake_ctid'::text, '(0,1)'::tid); -- fails
DROP VIEW tid_view_fake_ctid;

DROP TABLE tid_tab CASCADE;
