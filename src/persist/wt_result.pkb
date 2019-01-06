create or replace package body wt_result
as

----------------------
--  Private Procedures
----------------------

------------------------------------------------------------
procedure adhoc_report
      (in_assertion       in varchar2
      ,in_status          in varchar2
      ,in_details         in varchar2
      ,in_testcase_name   in varchar2
      ,in_message         in varchar2)
is
begin
   g_results_rec.testcase_name := in_testcase_name;
   g_results_rec.message       := in_message;
   g_results_rec.status        := in_status;
   g_results_rec.assertion     := in_assertion;
   g_results_rec.details       := in_details;
end adhoc_report;


---------------------
--  Public Procedures
---------------------

------------------------------------------------------------
procedure initialize
      (in_test_run_id   in wt_test_runs.id%TYPE)
is
   l_results_recNULL  wt_results_vw%ROWTYPE;
begin
   if in_test_run_id is NULL
   then
      raise_application_error(-20009, '"in_test_run_id" cannot be NULL');
   end if;
   g_results_rec := l_results_recNULL;
   g_results_rec.test_run_id  := in_test_run_id;
   g_results_rec.result_seq   := 0;
   g_results_rec.executed_dtm := systimestamp;
   g_results_nt := results_nt_type(null);
end initialize;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_initialize
   is
      l_results_recNULL  wt_results_vw%ROWTYPE;
      l_results_recSAVE  wt_results_vw%ROWTYPE;
      l_results_recTEST  wt_results_vw%ROWTYPE;
      l_results_ntSAVE   results_nt_type;
      l_results_ntTEST   results_nt_type;
   begin
      --------------------------------------  WTPLSQL Testing --
      l_results_ntSAVE  := g_results_nt;
      l_results_recSAVE := g_results_rec;
      g_results_rec     := l_results_recNULL;
      initialize(-99);
      l_results_recTEST := g_results_rec;
      g_results_rec     := l_results_recSAVE;
      l_results_ntTEST  := g_results_nt;
      g_results_nt      := l_results_ntSAVE;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Initialize Happy Path';
      wt_assert.eq (
         msg_in          => 'l_results_recTEST.test_run_id',
         check_this_in   => l_results_recTEST.test_run_id,
         against_this_in => -99);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_results_recTEST.result_seq',
         check_this_in   => l_results_recTEST.result_seq,
         against_this_in => 0);
      wt_assert.isnotnull (
         msg_in          => 'l_results_recTEST.executed_dtm',
         check_this_in   => l_results_recTEST.executed_dtm);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_results_recTEST.interval_msecs',
         check_this_in   => l_results_recTEST.interval_msecs);
      wt_assert.isnull (
         msg_in          => 'l_results_recTEST.assertion',
         check_this_in   => l_results_recTEST.assertion);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_results_recTEST.status',
         check_this_in   => l_results_recTEST.status);
      wt_assert.isnull (
         msg_in          => 'l_results_recTEST.details',
         check_this_in   => l_results_recTEST.details);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_results_recTEST.testcase_id',
         check_this_in   => l_results_recTEST.testcase_id);
      wt_assert.isnull (
         msg_in          => 'l_results_recTEST.message',
         check_this_in   => l_results_recTEST.message);
      wt_assert.eq (
         msg_in          => 'l_results_ntTEST.COUNT',
         check_this_in   => l_results_ntTEST.COUNT,
         against_this_in => 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_results_ntTEST(1).test_run_id',
         check_this_in   => l_results_ntTEST(1).test_run_id);
      wt_assert.raises (
         msg_in         => 'Raises ORA-20009',
         check_call_in  => 'begin wt_result.initialize(NULL); end;',
         against_exc_in => 'ORA-20009: "in_test_run_id" cannot be NULL');
   end t_initialize;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
-- Because this procedure is called to cleanup after errors,
--  it must be able to run multiple times without causing damage.
procedure finalize
is
   l_results_rec   wt_results%ROWTYPE;
begin
   if g_results_rec.test_run_id IS NULL
   then
      return;
   end if;
   -- There is always an extra NULL element in the g_results_nt array.
   for i in 1 .. g_results_nt.COUNT - 1
   loop
      l_results_rec.TEST_RUN_ID    := g_results_nt(i).TEST_RUN_ID;
      l_results_rec.RESULT_SEQ     := g_results_nt(i).RESULT_SEQ;
      l_results_rec.TESTCASE_ID    := g_results_nt(i).TESTCASE_ID;
      l_results_rec.EXECUTED_DTM   := g_results_nt(i).EXECUTED_DTM;
      l_results_rec.INTERVAL_MSECS := g_results_nt(i).INTERVAL_MSECS;
      l_results_rec.ASSERTION      := g_results_nt(i).ASSERTION;
      l_results_rec.STATUS         := g_results_nt(i).STATUS;
      l_results_rec.MESSAGE        := g_results_nt(i).MESSAGE;
      l_results_rec.DETAILS        := g_results_nt(i).DETAILS;
      insert into wt_results values l_results_rec;
   end loop;
end finalize;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_finalize
   is
      --------------------------------------  WTPLSQL Testing --
      type num_recs_aa_type is table of number index by varchar2(50);
      num_recs_aa   num_recs_aa_type;
      l_test_runs_rec      wt_test_runs%ROWTYPE;
      l_results_recNULL    wt_results_vw%ROWTYPE;
      l_results_recSAVE    wt_results_vw%ROWTYPE;
      l_results_recTEST    wt_results_vw%ROWTYPE;
      l_results_ntSAVE     results_nt_type;
      l_results_ntTEST     results_nt_type;
      l_num_recs           number;
   begin
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := '   ';
      l_results_ntSAVE     := g_results_nt;    -- Capture Original Values
      l_results_recSAVE    := g_results_rec;   -- Capture Original Values
      --------------------------------------  WTPLSQL Testing --
      -- Can't Test in this block because g_results_rec has test data
      g_results_rec  := l_results_recNULL;
      g_results_rec.test_run_id    := -99;
      g_results_rec.result_seq     := 1;
      g_results_rec.executed_dtm   := systimestamp;
      g_results_rec.interval_msecs := 99;
      --------------------------------------  WTPLSQL Testing --
      g_results_rec.assertion     := 'FINALTEST';
      g_results_rec.status        := wt_assert.C_PASS;
      g_results_rec.details       := 'This is a WT_RESULT.FINALIZE Test';
      g_results_nt := results_nt_type(null);
      g_results_nt(1) := g_results_rec;
      g_results_nt.extend;  -- Finalize expects that last element to be NULL
      --------------------------------------  WTPLSQL Testing --
      -- Can't Test in this block because g_results_rec has test data
      g_results_rec.test_run_id   := NULL;
      select count(*)
       into  num_recs_aa('Finalize Before NULL Test Record Count')
       from  wt_results
       where test_run_id = -99;
      finalize;
      --------------------------------------  WTPLSQL Testing --
      select count(*)
       into  num_recs_aa('Finalize After NULL Test Record Count')
       from  wt_results
       where test_run_id = -99;
      rollback;    -- UNDO all database changes
      g_results_rec.test_run_id   := -99;
      --------------------------------------  WTPLSQL Testing --
      -- Can't Test in this block because g_results_rec has test data
      l_test_runs_rec.id           := -99;
      l_test_runs_rec.start_dtm    := systimestamp;
      --l_test_runs_rec.runner_name  := 'Finalize Test';
      --l_test_runs_rec.runner_owner := 'BOGUS';
      insert into wt_test_runs values l_test_runs_rec;
      --------------------------------------  WTPLSQL Testing --
      finalize;    -- g_results_nt is still loaded with one element
      l_results_ntTEST  := g_results_nt;
      l_results_recTEST := g_results_rec;
      select count(*)
       into  num_recs_aa('Finalize Record Count Test')
       from  wt_results
       where test_run_id = -99;
      delete from wt_results where test_run_id = -99;
      delete from wt_test_runs where id = -99;
      commit;      -- UNDO all database changes
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Finalize Happy Path';
      -- Restore values so we can test
      g_results_rec := l_results_recSAVE;
      g_results_nt  := l_results_ntSAVE;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'Before NULL Test Record Count',
         check_this_in   => num_recs_aa('Finalize Before NULL Test Record Count'),
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'After NULL Test Record Count',
         check_this_in   => num_recs_aa('Finalize After NULL Test Record Count'),
         against_this_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in        => 'l_results_recTEST.test_run_id',
         check_this_in => l_results_recTEST.test_run_id);
      wt_assert.eq (
         msg_in          => 'l_results_ntTEST.COUNT',
         check_this_in   => l_results_ntTEST.COUNT,
         against_this_in => 1);
      wt_assert.eq (
         msg_in          => 'Record Count Test',
         check_this_in   => num_recs_aa('Finalize Record Count Test'),
         against_this_in => 1);
   end t_finalize;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
procedure save
      (in_assertion      in varchar2
      ,in_status         in varchar2
      ,in_details        in varchar2
      ,in_testcase_name  in varchar2
      ,in_message        in varchar2)
is
   l_current_tstamp  timestamp;
begin
   if g_results_rec.test_run_id IS NULL
   then
      adhoc_report(in_assertion
                  ,in_status
                  ,in_details
                  ,in_testcase_name
                  ,in_message);
      return;
   end if;
   -- Set the time and interval
   l_current_tstamp := systimestamp;
   g_results_rec.interval_msecs := extract(day from (
                                  l_current_tstamp - g_results_rec.executed_dtm
                                  ) * 86400 * 1000);
   g_results_rec.executed_dtm  := l_current_tstamp;
   -- Set the IN variables
   g_results_rec.assertion     := in_assertion;
   g_results_rec.status        := in_status;
   g_results_rec.details       := substr(in_details,1,4000);
   g_results_rec.testcase_name := substr(in_testcase_name,1,128);
   g_results_rec.message       := substr(in_message,1,200);
   -- Increment, Load, and Extend
   g_results_rec.result_seq    := g_results_rec.result_seq + 1;
   g_results_nt(g_results_nt.COUNT) := g_results_rec;
   g_results_nt.extend;

end save;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_save_testing
   is
      --------------------------------------  WTPLSQL Testing --
      TYPE l_dbmsout_buff_type is table of varchar2(32767);
      l_dbmsout_buff   l_dbmsout_buff_type := l_dbmsout_buff_type(1);
      l_test_run_id    number;
      l_dbmsout_line   varchar2(32767);
      l_dbmsout_stat   number;
      l_nt_count       number;
   begin
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Ad Hoc Save Happy Path Setup';
      dbms_output.enable;
      -- Save/Clear the DBMS_OUPTUT Buffer
      loop
         DBMS_OUTPUT.GET_LINE (
            line   => l_dbmsout_line,
            status => l_dbmsout_stat);
         exit when l_dbmsout_stat != 0;
         l_dbmsout_buff(l_dbmsout_buff.COUNT) := l_dbmsout_line;
         l_dbmsout_buff.extend;
      end loop;
      wt_assert.isnotnull (
         msg_in        => 'l_dbmsout_buff.COUNT - 1',
         check_this_in => l_dbmsout_buff.COUNT - 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Ad Hoc Save Testing Happy Path';
      l_test_run_id  := g_results_rec.test_run_id;
      g_results_rec.test_run_id := NULL;
      wt_result.save (
         in_assertion     => 'SELFTEST1',
         in_status        => wt_assert.C_PASS,
         in_details       => 't_save_testing Details',
         in_testcase_name => wt_assert.g_testcase_name,
         in_message       => 't_save_testing Message');
      g_results_rec.test_run_id := l_test_run_id;
      --------------------------------------  WTPLSQL Testing --
      DBMS_OUTPUT.GET_LINE (
         line   => l_dbmsout_line,
         status => l_dbmsout_stat);
      wt_assert.eq (
         msg_in          => 'DBMS_OUTPUT Status',
         check_this_in   => l_dbmsout_stat,
         against_this_in => 0);
      --------------------------------------  WTPLSQL Testing --
      if wt_assert.last_pass
      then
         wt_assert.isnotnull (
            msg_in        => 'DBMS_OUTPUT Line',
            check_this_in => l_dbmsout_line);
         wt_assert.this (
            msg_in        => 'Save Testing NULL Test DBMS_OUTPUT 3 Message',
            check_this_in => (l_dbmsout_line like '%' || wt_assert.g_testcase_name ||
                             '%t_save_testing %'));
      --------------------------------------  WTPLSQL Testing --
         if not wt_assert.last_pass
         then
            -- No match, put the line back into DBMS_OUTPUT buffer and end this.
            DBMS_OUTPUT.PUT_LINE(l_dbmsout_line);
         end if;
      end if;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Ad Hoc Save Happy Path Teardown';
      -- Restore the DBMS_OUPTUT Buffer
      for i in 1 .. l_dbmsout_buff.COUNT - 1
      loop
         DBMS_OUTPUT.PUT_LINE(l_dbmsout_buff(i));
      end loop;
      wt_assert.isnotnull (
         msg_in        => 'l_dbmsout_buff.COUNT - 1',
         check_this_in =>  l_dbmsout_buff.COUNT - 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Save Testing Happy Path';
      l_nt_count     := g_results_nt.COUNT;
      wt_result.save (
         in_assertion     => 'SELFTEST2',
         in_status        => wt_assert.C_PASS,
         in_details       => 't_save_testing Testing Details',
         in_testcase_name => wt_assert.g_testcase_name,
         in_message       => 't_save_testing Testing Message');
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'g_results_nt.COUNT',
         check_this_in   => g_results_nt.COUNT,
         against_this_in => l_nt_count + 1);
      if not wt_assert.last_pass
      then
         return;   -- Something went wrong, end this now.
      end if;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'g_results_nt(' || l_nt_count || ').assetion',
         check_this_in   => g_results_nt(l_nt_count).assertion,
         against_this_in => 'SELFTEST2');
      wt_assert.eq (
         msg_in          => 'g_results_nt(' || l_nt_count || ').status',
         check_this_in   => g_results_nt(l_nt_count).status,
         against_this_in => wt_assert.C_PASS);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'g_results_nt(' || l_nt_count || ').details',
         check_this_in   => g_results_nt(l_nt_count).details,
         against_this_in => 't_save_testing Testing Details');
      wt_assert.eq (
         msg_in          => 'g_results_nt(' || l_nt_count || ').testcase_name',
         check_this_in   => g_results_nt(l_nt_count).testcase_name,
         against_this_in => wt_assert.g_testcase_name);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'g_results_nt(' || l_nt_count || ').message',
         check_this_in   => g_results_nt(l_nt_count).message,
         against_this_in => 't_save_testing Testing Message');
      wt_assert.isnotnull (
         msg_in          => 'g_results_nt(' || l_nt_count || ').interval_msecs',
         check_this_in   => g_results_nt(l_nt_count).interval_msecs);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnotnull (
         msg_in          => 'g_results_nt(' || l_nt_count || ').executed_dtm',
         check_this_in   => g_results_nt(l_nt_count).executed_dtm);
      wt_assert.isnotnull (
         msg_in          => 'g_results_nt(' || l_nt_count || ').result_seq',
         check_this_in   => g_results_nt(l_nt_count).result_seq);
      --  Can't Delete Test Element.  g_results_nt.COUNT is not reduced
      --    because nested tables are not dense.
      --g_results_nt.delete(l_nt_count + 1);
   end t_save_testing;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
procedure delete_records
      (in_test_run_id  in number)
is
begin
   delete from wt_results
    where test_run_id = in_test_run_id;
end delete_records;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_delete_records
   is
      --------------------------------------  WTPLSQL Testing --
      l_test_runs_rec  wt_test_runs%ROWTYPE;
      l_results_rec    wt_results%ROWTYPE;
      l_num_recs       number;
   begin
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase_name := 'Delete Records Happy Path';
      select count(*) into l_num_recs
       from  wt_results
       where test_run_id = -99;
      wt_assert.isnotnull (
         msg_in        => 'Before Insert Count',
         check_this_in => l_num_recs);
      --------------------------------------  WTPLSQL Testing --
      l_test_runs_rec.id           := -99;
      l_test_runs_rec.start_dtm    := sysdate;
      l_test_runs_rec.runner_name  := 'Delete Records Test';
      l_test_runs_rec.runner_owner := 'BOGUS';
      insert into wt_test_runs values l_test_runs_rec;
      l_results_rec.test_run_id    := -99;
      --------------------------------------  WTPLSQL Testing --
      l_results_rec.result_seq     := 1;
      l_results_rec.executed_dtm   := sysdate;
      l_results_rec.interval_msecs := 99;
      l_results_rec.assertion      := 'DELRECTEST';
      l_results_rec.status         := wt_assert.C_PASS;
      l_results_rec.details        := 'This is a WT_RESULT.DELETE_RECORDS Test';
      insert into wt_results values l_results_rec;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eqqueryvalue (
         msg_in            => 'After Insert Count',
         check_query_in    => 'select count(*) from wt_results' ||
                              ' where test_run_id = -99',
         against_value_in  => l_num_recs + 1);
      delete_records(-99);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eqqueryvalue (
         msg_in            => 'After Test Count',
         check_query_in    => 'select count(*) from wt_results' ||
                              ' where test_run_id = -99',
         against_value_in  => l_num_recs);
      rollback;
      wt_assert.eqqueryvalue (
         msg_in            => 'After ROLLBACK Count',
         check_query_in    => 'select count(*) from wt_results' ||
                              ' where test_run_id = -99',
         against_value_in  => l_num_recs);
   end t_delete_records;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


--==============================================================--
$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure WTPLSQL_RUN  --% WTPLSQL SET DBOUT "WT_RESULT:PACKAGE BODY" %--
   is
   begin
      --------------------------------------  WTPLSQL Testing --
      t_initialize;
      t_finalize;
      t_save_testing;
      t_delete_records;
   end WTPLSQL_RUN;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------
--==============================================================--


end wt_result;