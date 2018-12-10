
--
--  Core Installation
--
--   Run as SYS
--

-- Capture output
spool install
set showmode off
set serveroutput on size unlimited format truncated

WHENEVER SQLERROR exit SQL.SQLCODE

begin
   if USER not in ('SYS')
   then
      raise_application_error (-20000,
        'Not logged in as SYS');
   end if;
end;
/

-- Shared Setup Script
@../common_setup.sql

WHENEVER SQLERROR continue

-- Create the schema owner.

create user &schema_owner. identified by &schema_owner.
   default tablespace users
   quota unlimited on users
   temporary tablespace temp;

grant create session        to &schema_owner.;
grant create type           to &schema_owner.;
grant create sequence       to &schema_owner.;
grant create table          to &schema_owner.;
grant create trigger        to &schema_owner.;
grant create view           to &schema_owner.;
grant create procedure      to &schema_owner.;
grant create database link  to &schema_owner.;
grant create job            to &schema_owner.;
grant create public synonym to &schema_owner.;

-- For DBOUT Check.
grant select on dba_objects       to &schema_owner. with grant option;
-- For Qualified Test Runners View
grant select on dba_procedures    to &schema_owner. with grant option;
-- For Profiler
grant select on dba_source        to &schema_owner. with grant option;
-- For GUI
grant select on sys.gv_$parameter to &schema_owner. with grant option;

begin
   for buff in (select p.value PLSQL_CCFLAGS
                 from  dual  d
                  left join v$parameter  p
                       on  p.name in 'plsql_ccflags')
   loop
      dbms_output.put_line('PLSQL_CCFLAGS Before: ' || buff.PLSQL_CCFLAGS);
   end loop;
end;
/

-- This block is IDEMPOTENT. It can run more than once and give
--   the same result.
declare
   C_FLAG  CONSTANT varchar2(100) := 'WTPLSQL_ENABLE:';
   parm_value   v$parameter.value%TYPE;
   procedure set_plsql_ccflags (in_value in varchar2) is begin
      execute immediate 'alter system set PLSQL_CCFLAGS = ''' ||
                         in_value || ''' scope=BOTH';
   end set_plsql_ccflags;
begin
   select value into parm_value
    from  v$parameter
    where name in 'plsql_ccflags';
   if nvl(length(parm_value),0) = 0
   then
      -- No Flags have been set
      set_plsql_ccflags(C_FLAG || 'TRUE');
   elsif instr(parm_value, C_FLAG) = 0
   then
      -- C_FLAG is not already present
      set_plsql_ccflags(C_FLAG || 'TRUE, ' || parm_value);
   end if;
end;
/

begin
   for buff in (select p.value PLSQL_CCFLAGS
                 from  dual  d
                  left join v$parameter  p
                       on  p.name in 'plsql_ccflags')
   loop
      dbms_output.put_line('PLSQL_CCFLAGS After: ' || buff.PLSQL_CCFLAGS);
   end loop;
end;
/


WHENEVER SQLERROR exit SQL.SQLCODE

-- Connect as SCHEMA_OWNER
connect &schema_owner./&schema_owner.&connect_string.
set serveroutput on size unlimited format truncated

begin
   if USER != upper('&schema_owner')
   then
      raise_application_error (-20000,
        'Not logged in as &schema_owner');
   end if;
end;
/

WHENEVER SQLERROR continue


-- Core Tables
@hooks.tab

@wt_version.tab

@wt_self_test.tab


-- Package Specifications
@core_data.pks
/

@hook.pks
/

@wtplsql.pks
/
grant execute on wtplsql to public;
create or replace public synonym wtplsql    for wtplsql;
create or replace public synonym wt_wtplsql for wtplsql;

@wt_assert.pks
/
grant execute on wt_assert to public;
create or replace public synonym wt_assert for wt_assert;
create or replace public synonym utassert  for wt_assert;

@wt_text_report.pks
/
grant execute on wt_text_report to public;
create or replace public synonym wt_text_report for wt_text_report;


-- Procedures
@wt_execute_test_runner.prc
/
grant execute on wt_execute_test_runner to public;
create or replace public synonym wt_execute_test_runner for wt_execute_test_runner;


-- Package Bodies
@core_data.pkb
/

@hook.pkb
/

@wtplsql.pkb
/

@wt_assert.pkb
/

@wt_text_report.pkb
/

-- Views
@wt_qual_test_runners_vw.vw
/

@wt_scheduler_jobs_vw.vw
/

-- Configuration Data

-- This is the default test runner execution procedure
insert into hooks (hook_name, seq, run_string)
   values ('execute_test_runner', 1, 'begin wt_execute_test_runner; end;');

-- Run this report after testing because this is no storage
insert into hooks (hook_name, seq, run_string)
   values ('after_test_run', 1, 'begin wt_text_report.dbms_out(10); end;');

-- This is the default ad-hoc result report
insert into hooks (hook_name, seq, run_string)
   values ('ad_hoc_report', 1, 'begin wt_text_report.ad_hoc_result; end;');

commit;

set showmode on
spool off
