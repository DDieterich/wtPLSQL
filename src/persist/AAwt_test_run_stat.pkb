create or replace package body wt_test_run_stat
as

   TYPE tc_aa_type is
        table of wt_testcase_runs%ROWTYPE
        index by varchar2(50);
   g_tc_aa  tc_aa_type;
   g_rec    wt_test_run_stats%ROWTYPE;


----------------------
--  Private Procedures
----------------------


---------------------
--  Public Procedures
---------------------


------------------------------------------------------------
procedure initialize
is
   l_recNULL  wt_test_run_stats%ROWTYPE;
begin
   g_rec := l_recNULL;
   g_tc_aa.delete;
end initialize;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_initialize
   is
      l_tc_aaSAVE  tc_aa_type;
      l_recSAVE    wt_test_run_stats%ROWTYPE;
      l_tc_aaTEST  tc_aa_type;
      l_recTEST    wt_test_run_stats%ROWTYPE;
   begin
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'Initialize Happy Path 1 Setup';
      l_tc_aaTEST('TESTCASE1').test_run_id := -2;
      l_recTEST.test_run_id := -1;
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').test_run_id',
         check_this_in   =>  l_tc_aaTEST('TESTCASE1').test_run_id,
         against_this_in =>  -2 );
      wt_assert.eq (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   =>  l_recTEST.test_run_id,
         against_this_in =>  -1 );
      --------------------------------------  WTPLSQL Testing --
      l_tc_aaSAVE := g_tc_aa;
      l_recSAVE   := g_rec;
      g_tc_aa     := l_tc_aaTEST;
      g_rec       := l_recTEST;
      initialize;
      l_tc_aaTEST := g_tc_aa;
      l_recTEST   := g_rec;
      g_tc_aa     := l_tc_aaSAVE;
      g_rec       := l_recSAVE;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'Initialize Happy Path 1';
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST.COUNT',
         check_this_in   =>  l_tc_aaTEST.COUNT,
         against_this_in =>  0 );
      wt_assert.isnull (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   =>  l_recTEST.test_run_id );
   end t_initialize;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
procedure add_result
      (in_results_rec  in wt_results%ROWTYPE)
is
   tc  varchar2(50);
begin
   -- If this raises an exception, it must be done before any other values
   --   are set because they will not be rolled-back after the "raise".
   case in_results_rec.status
      when 'PASS' then
         g_rec.passes := nvl(g_rec.passes,0) + 1;
      when 'FAIL' then
         g_rec.failures := nvl(g_rec.failures,0) + 1;
      else
         raise_application_error(-20010, 'Unknown Result status "' ||
                                      in_results_rec.status || '"');
   end case;
   --
   g_rec.test_run_id := in_results_rec.test_run_id;
   g_rec.asserts     := nvl(g_rec.asserts,0) + 1;
   g_rec.min_interval_msecs := least(nvl(g_rec.min_interval_msecs,999999999)
                                    ,in_results_rec.interval_msecs);
   g_rec.max_interval_msecs := greatest(nvl(g_rec.max_interval_msecs,0)
                                       ,in_results_rec.interval_msecs);
   g_rec.tot_interval_msecs := nvl(g_rec.tot_interval_msecs,0) +
                               in_results_rec.interval_msecs;
   --
   tc := in_results_rec.testcase;
   g_tc_aa(tc).testcase    := tc;
   g_tc_aa(tc).test_run_id := in_results_rec.test_run_id;
   g_tc_aa(tc).asserts     := nvl(g_tc_aa(tc).asserts,0) + 1;
   --
   case in_results_rec.status
      when 'PASS' then
         g_tc_aa(tc).passes := nvl(g_tc_aa(tc).passes,0) + 1;
      when 'FAIL' then
         g_tc_aa(tc).failures := nvl(g_tc_aa(tc).failures,0) + 1;
      -- No need to check "ELSE" because it would have been caught above
   end case;
   --
   g_tc_aa(tc).min_interval_msecs := least(nvl(g_tc_aa(tc).min_interval_msecs,999999999)
                                          ,in_results_rec.interval_msecs);
   g_tc_aa(tc).max_interval_msecs := greatest(nvl(g_tc_aa(tc).max_interval_msecs,0)
                                             ,in_results_rec.interval_msecs);
   g_tc_aa(tc).tot_interval_msecs := nvl(g_tc_aa(tc).tot_interval_msecs,0) +
                                     in_results_rec.interval_msecs;
   --
end add_result;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_add_result
   is
      l_tc_aaSAVE   tc_aa_type;
      l_recSAVE     wt_test_run_stats%ROWTYPE;
      l_tc_aaTEST   tc_aa_type;
      l_recTEST     wt_test_run_stats%ROWTYPE;
      l_resultTEST  wt_results%ROWTYPE;
      l_sqlerrm     varchar2(4000);
   begin
      --------------------------------------  WTPLSQL Testing --
      -- Overview:
      -- 1) Save results in temporary variables
      -- 2) Clear ADD_RESULT variables
      -- 3) Call ADD_RESULT several times with test data.
      -- 4) Capture test results
      -- 5) Restore saved results
      -- 6) Confirm the test results using WT_ASSERT.
      --------------------------------------  WTPLSQL Testing --
      l_tc_aaSAVE := g_tc_aa;
      l_recSAVE   := g_rec;
      g_tc_aa     := l_tc_aaTEST;
      g_rec       := l_recTEST;
      l_resultTEST.test_run_id    := -10;
      l_resultTEST.interval_msecs := 10;
      l_resultTEST.status         := 'PASS';
      l_resultTEST.testcase       := 'TESTCASE1';
      add_result(l_resultTEST);
      --------------------------------------  WTPLSQL Testing --
      l_resultTEST.interval_msecs := 20;
      l_resultTEST.status         := 'FAIL';
      l_resultTEST.testcase       := 'TESTCASE1';
      add_result(l_resultTEST);
      l_resultTEST.interval_msecs := 30;
      l_resultTEST.status         := 'ERR';
      l_resultTEST.testcase       := 'TESTCASE1';
      add_result(l_resultTEST);
      --------------------------------------  WTPLSQL Testing --
      l_resultTEST.interval_msecs := 40;
      l_resultTEST.status         := 'ABC';
      l_resultTEST.testcase       := 'TESTCASE1';
      begin
         add_result(l_resultTEST);
         l_sqlerrm := SQLERRM;
      exception when others then
         l_sqlerrm := SQLERRM;
      end;
      --------------------------------------  WTPLSQL Testing --
      l_tc_aaTEST := g_tc_aa;
      l_recTEST   := g_rec;
      g_tc_aa     := l_tc_aaSAVE;
      g_rec       := l_recSAVE;
      wt_assert.g_testcase := 'Add Result Testing';
      wt_assert.eq (
          msg_in          => 'Add Result Sad Path 1',
          check_this_in   => 'ORA-20010: Unknown Result status "ABC"',
          against_this_in => l_sqlerrm);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   => l_recTEST.test_run_id,
         against_this_in => -10);
      wt_assert.eq (
         msg_in          => 'l_recTEST.asserts',
         check_this_in   => l_recTEST.asserts,
         against_this_in => 3);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.passes',
         check_this_in   => l_recTEST.passes,
         against_this_in => 1);
      wt_assert.eq (
         msg_in          => 'l_recTEST.failures',
         check_this_in   => l_recTEST.failures,
         against_this_in => 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.errors',
         check_this_in   => l_recTEST.errors,
         against_this_in => 1);
      wt_assert.eq (
         msg_in          => 'l_recTEST.min_interval_msecs',
         check_this_in   => l_recTEST.min_interval_msecs,
         against_this_in => 10);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.max_interval_msecs',
         check_this_in   => l_recTEST.max_interval_msecs,
         against_this_in => 30);
      wt_assert.eq (
         msg_in          => 'l_recTEST.tot_interval_msecs',
         check_this_in   => l_recTEST.tot_interval_msecs,
         against_this_in => 60);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').test_run_id',
         check_this_in   => l_tc_aaTEST('TESTCASE1').test_run_id,
         against_this_in => -10);
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').asserts',
         check_this_in   => l_tc_aaTEST('TESTCASE1').asserts,
         against_this_in => 3);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').passes',
         check_this_in   => l_tc_aaTEST('TESTCASE1').passes,
         against_this_in => 1);
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').failures',
         check_this_in   => l_tc_aaTEST('TESTCASE1').failures,
         against_this_in => 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').errors',
         check_this_in   => l_tc_aaTEST('TESTCASE1').errors,
         against_this_in => 1);
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').min_interval_msecs',
         check_this_in   => l_tc_aaTEST('TESTCASE1').min_interval_msecs,
         against_this_in => 10);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').max_interval_msecs',
         check_this_in   => l_tc_aaTEST('TESTCASE1').max_interval_msecs,
         against_this_in => 30);
      wt_assert.eq (
         msg_in          => 'l_tc_aaTEST(''TESTCASE1'').tot_interval_msecs',
         check_this_in   => l_tc_aaTEST('TESTCASE1').tot_interval_msecs,
         against_this_in => 60);
   end t_add_result;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
procedure add_profile
      (in_dbout_profiles_rec  in wt_dbout_profiles%ROWTYPE)
is
begin
   -- If this raises an exception, it must be done before any other values
   --   are set because they will not be rolled-back after the "raise".
   case in_dbout_profiles_rec.status
      when 'EXEC' then
         g_rec.executed_lines := nvl(g_rec.executed_lines,0) + 1;
         -- Only count the executed time.
         g_rec.min_executed_usecs := least(nvl(g_rec.min_executed_usecs,999999999)
                                          ,in_dbout_profiles_rec.min_usecs);
         g_rec.max_executed_usecs := greatest(nvl(g_rec.max_executed_usecs,0)
                                             ,in_dbout_profiles_rec.max_usecs);
         g_rec.tot_executed_usecs := nvl(g_rec.tot_executed_usecs,0) +
                                     ( in_dbout_profiles_rec.total_usecs /
                                       in_dbout_profiles_rec.total_occur  );
      when 'IGNR' then
         g_rec.ignored_lines := nvl(g_rec.ignored_lines,0) + 1;
      when 'EXCL' then
         g_rec.excluded_lines := nvl(g_rec.excluded_lines,0) + 1;
      when 'NOTX' then
         g_rec.notexec_lines := nvl(g_rec.notexec_lines,0) + 1;
      when 'UNKN' then
         g_rec.unknown_lines := nvl(g_rec.unknown_lines,0) + 1;
      else
         raise_application_error(-20011, 'Unknown Profile status "' ||
                                       in_dbout_profiles_rec.status || '"');
   end case;
   g_rec.test_run_id    := in_dbout_profiles_rec.test_run_id;
   g_rec.profiled_lines := nvl(g_rec.profiled_lines,0) + 1;
end add_profile;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_add_profile
   is
      l_recSAVE      wt_test_run_stats%ROWTYPE;
      l_recTEST      wt_test_run_stats%ROWTYPE;
      l_profileTEST  wt_dbout_profiles%ROWTYPE;
      l_sqlerrm      varchar2(4000);
   begin
      --------------------------------------  WTPLSQL Testing --
      -- Overview:
      -- 1) Save results in temporary variables
      -- 2) Clear ADD_PROFILE variables
      -- 3) Call ADD_PROFILE several times with test data.
      -- 4) Capture test results
      -- 5) Restore saved results
      -- 6) Confirm the test results using WT_ASSERT.
      --------------------------------------  WTPLSQL Testing --
      l_recSAVE   := g_rec;
      g_rec       := l_recTEST;
      l_profileTEST.test_run_id := -20;
      l_profileTEST.min_usecs   := 10;
      l_profileTEST.max_usecs   := 20;
      l_profileTEST.total_usecs := 30;
      l_profileTEST.total_occur := 1;
      l_profileTEST.status := 'EXEC';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'EXEC';
      add_profile(l_profileTEST);
      --------------------------------------  WTPLSQL Testing --
      l_profileTEST.status := 'EXEC';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'EXEC';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'EXEC';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'IGNR';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'IGNR';
      add_profile(l_profileTEST);
      --------------------------------------  WTPLSQL Testing --
      l_profileTEST.status := 'IGNR';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'IGNR';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'NOTX';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'NOTX';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'NOTX';
      add_profile(l_profileTEST);
      --------------------------------------  WTPLSQL Testing --
      l_profileTEST.status := 'EXCL';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'EXCL';
      add_profile(l_profileTEST);
      l_profileTEST.status := 'UNKN';
      add_profile(l_profileTEST);
      --------------------------------------  WTPLSQL Testing --
      l_profileTEST.status := 'ABC';
      begin
         add_profile(l_profileTEST);
         l_sqlerrm := SQLERRM;
      exception when others then
         l_sqlerrm := SQLERRM;
      end;
      l_recTEST := g_rec;
      g_rec     := l_recSAVE;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'Add Profile Testing';
      wt_assert.eq (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   => l_recTEST.test_run_id,
         against_this_in => -20);
      wt_assert.eq (
         msg_in          => 'l_recTEST.profiled_lines',
         check_this_in   => l_recTEST.profiled_lines,
         against_this_in => 15);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.min_executed_usecs',
         check_this_in   => l_recTEST.min_executed_usecs,
         against_this_in => 10);
      wt_assert.eq (
         msg_in          => 'l_recTEST.max_executed_usecs',
         check_this_in   => l_recTEST.max_executed_usecs,
         against_this_in => 20);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.tot_executed_usecs',
         check_this_in   => l_recTEST.tot_executed_usecs,
         against_this_in => 150);
      wt_assert.eq (
         msg_in          => 'l_recTEST.executed_lines',
         check_this_in   => l_recTEST.executed_lines,
         against_this_in => 5);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.ignored_lines',
         check_this_in   => l_recTEST.ignored_lines,
         against_this_in => 4);
      wt_assert.eq (
         msg_in          => 'l_recTEST.notexec_lines',
         check_this_in   => l_recTEST.notexec_lines,
         against_this_in => 3);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.excluded_lines',
         check_this_in   => l_recTEST.excluded_lines,
         against_this_in => 2);
      wt_assert.eq (
         msg_in          => 'l_recTEST.unknown_lines',
         check_this_in   => l_recTEST.unknown_lines,
         against_this_in => 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
          msg_in          => 'Add Result Sad Path 1',
          check_this_in   => 'ORA-20011: Unknown Profile status "ABC"',
          against_this_in => l_sqlerrm);
   end t_add_profile;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
procedure finalize
is
   l_executable_lines   number;
   tc                   varchar2(50);
begin
   --
   if g_rec.test_run_id is null
   then
      initialize;
      return;
   end if;
   --
   g_rec.testcases := g_tc_aa.COUNT;
   g_rec.asserts   := nvl(g_rec.asserts ,0);
   g_rec.passes    := nvl(g_rec.passes  ,0);
   g_rec.failures  := nvl(g_rec.failures,0);
   g_rec.errors    := nvl(g_rec.errors  ,0);
   --
   if g_rec.asserts != 0
   then
      g_rec.test_yield := round(g_rec.passes/g_rec.asserts, 3);
      g_rec.avg_interval_msecs := round(g_rec.tot_interval_msecs/g_rec.asserts, 3);
   end if;
   --
   if g_rec.profiled_lines is not null
   then
      g_rec.executed_lines  := nvl(g_rec.executed_lines ,0);
      g_rec.ignored_lines   := nvl(g_rec.ignored_lines,0);
      g_rec.excluded_lines  := nvl(g_rec.excluded_lines ,0);
      g_rec.notexec_lines   := nvl(g_rec.notexec_lines  ,0);
      g_rec.unknown_lines   := nvl(g_rec.unknown_lines  ,0);
      l_executable_lines    := g_rec.executed_lines + g_rec.notexec_lines;
      if l_executable_lines != 0
      then
         g_rec.code_coverage := round(g_rec.executed_lines/l_executable_lines, 3);
         g_rec.avg_executed_usecs := round(g_rec.tot_executed_usecs/l_executable_lines, 3);
      end if;
   end if;
   --
   insert into wt_test_run_stats values g_rec;
   --
   tc := g_tc_aa.FIRST;
   loop
      g_tc_aa(tc).asserts  := nvl(g_tc_aa(tc).asserts ,0);
      g_tc_aa(tc).passes   := nvl(g_tc_aa(tc).passes  ,0);
      g_tc_aa(tc).failures := nvl(g_tc_aa(tc).failures,0);
      g_tc_aa(tc).errors   := nvl(g_tc_aa(tc).errors  ,0);
      if g_rec.asserts != 0
      then
         g_tc_aa(tc).test_yield := round(g_tc_aa(tc).passes /
                                         g_tc_aa(tc).asserts, 3);
         g_tc_aa(tc).avg_interval_msecs := round(g_tc_aa(tc).tot_interval_msecs /
                                                 g_tc_aa(tc).asserts, 3);
      end if;
      insert into wt_testcase_runs values g_tc_aa(tc);
      exit when tc = g_tc_aa.LAST;
      tc := g_tc_aa.NEXT(tc);
   end loop;
   --
   initialize;
   --
end finalize;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_finalize
   is
      l_tc_aaSAVE    tc_aa_type;
      l_recSAVE      wt_test_run_stats%ROWTYPE;
      l_tc_aaTEST    tc_aa_type;
      l_recTEST      wt_test_run_stats%ROWTYPE;
      l_recNULL      wt_test_run_stats%ROWTYPE;
      l_tstat_rec    wt_testcase_runs%ROWTYPE;
      l_test_run_id  number       := -102;
      l_tc           varchar2(50) := 'TC2';
      l_sql_txt      varchar2(4000);
      l_sqlerrm      varchar2(4000);
      --------------------------------------  WTPLSQL Testing --
      procedure run_finalize (in_msg_txt in varchar2) is begin
         l_tc_aaSAVE := g_tc_aa;
         l_recSAVE   := g_rec;
         g_tc_aa     := l_tc_aaTEST;
         g_rec       := l_recTEST;
         begin
            finalize;
            l_sqlerrm := SQLERRM;
         exception when others then
            l_sqlerrm := SQLERRM;
         end;
      --------------------------------------  WTPLSQL Testing --
         l_tc_aaTEST := g_tc_aa;
         l_recTEST   := g_rec;
         g_tc_aa     := l_tc_aaSAVE;
         g_rec       := l_recSAVE;
         wt_assert.eq (
            msg_in          => in_msg_txt,
            check_this_in   => l_sqlerrm,
            against_this_in => 'ORA-0000: normal, successful completion');
      end run_finalize;
   begin
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'FINALIZE Happy Path Setup';
      l_sql_txt := 'insert into WT_TEST_RUNS' ||
                   ' (id, start_dtm, runner_owner, runner_name)' ||
         ' values (' || l_test_run_id || ', sysdate, USER, ''TESTRUNNER3'')';
      wt_assert.raises (
         msg_in         => 'Insert WT_TEST_RUNS Record',
         check_call_in  => l_sql_txt,
         against_exc_in => '');
      commit;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase  := 'FINALIZE Happy Path 1';
      l_tc_aaTEST.delete;
      l_recTEST := l_recNULL;
      l_recTEST.test_run_id := l_test_run_id;
      run_finalize('Run Finalize for Happy Path 1');
      --------------------------------------  WTPLSQL Testing --
      begin
         select * into l_recTEST
          from  WT_TEST_RUN_STATS
          where test_run_id = l_test_run_id;
         l_sqlerrm := SQLERRM;
      exception when others then
         l_sqlerrm := SQLERRM;
      end;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'Retieve WT_TEST_RUN_STATS record',
         check_this_in   => l_sqlerrm,
         against_this_in => 'ORA-0000: normal, successful completion');
      wt_assert.eq (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   => l_recTEST.test_run_id,
         against_this_in => l_test_run_id);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_recTEST.test_yield',
         check_this_in   => l_recTEST.test_yield);
      wt_assert.eq (
         msg_in          => 'l_recTEST.asserts',
         check_this_in   => l_recTEST.asserts,
         against_this_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.passes',
         check_this_in   => l_recTEST.passes,
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'l_recTEST.failures',
         check_this_in   => l_recTEST.failures,
         against_this_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.errors',
         check_this_in   => l_recTEST.errors,
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'l_recTEST.testcases',
         check_this_in   => l_recTEST.testcases,
         against_this_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_recTEST.min_interval_msecs',
         check_this_in   => l_recTEST.min_interval_msecs);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.avg_interval_msecs',
         check_this_in   => l_recTEST.avg_interval_msecs);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.max_interval_msecs',
         check_this_in   => l_recTEST.max_interval_msecs);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_recTEST.tot_interval_msecs',
         check_this_in   => l_recTEST.tot_interval_msecs);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.code_coverage',
         check_this_in   => l_recTEST.code_coverage);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.profiled_lines',
         check_this_in   => l_recTEST.profiled_lines);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_recTEST.executed_lines',
         check_this_in   => l_recTEST.executed_lines);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.ignored_lines',
         check_this_in   => l_recTEST.ignored_lines);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.excluded_lines',
         check_this_in   => l_recTEST.excluded_lines);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.isnull (
         msg_in          => 'l_recTEST.notexec_lines',
         check_this_in   => l_recTEST.notexec_lines);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.unknown_lines',
         check_this_in   => l_recTEST.unknown_lines);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.avg_executed_usecs',
         check_this_in   => l_recTEST.avg_executed_usecs);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eqqueryvalue (
         msg_in           => 'There should be no wt_testcase_runs records',
         check_query_in   => 'select count(*) from wt_testcase_runs' ||
                             ' where test_run_id = ' || l_test_run_id,
         against_value_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.raises (
         msg_in         => 'Delete WT_TEST_RUN_STATS Record',
         check_call_in  => 'delete from WT_TEST_RUN_STATS where test_run_id = ' ||
                                                              l_test_run_id,
         against_exc_in => '');
      commit;
      wt_assert.eqqueryvalue (
         msg_in           => 'There should be no WT_TEST_RUN_STATS records',
         check_query_in   => 'select count(*) from WT_TEST_RUN_STATS' ||
                             ' where test_run_id = ' || l_test_run_id,
         against_value_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'FINALIZE Happy Path 2';
      l_tc_aaTEST.delete;
      l_tc_aaTEST(l_tc||'a').test_run_id        := l_test_run_id;
      l_tc_aaTEST(l_tc||'a').testcase           := l_tc||'a';
      l_tc_aaTEST(l_tc||'a').asserts            := 3;
      l_tc_aaTEST(l_tc||'a').passes             := 2;
      l_tc_aaTEST(l_tc||'a').failures           := 1;
      --l_tc_aaTEST(l_tc||'a').errors             := null;
      l_tc_aaTEST(l_tc||'a').tot_interval_msecs := 300;
      --------------------------------------  WTPLSQL Testing --
      l_tc_aaTEST(l_tc||'b').test_run_id        := l_test_run_id;
      l_tc_aaTEST(l_tc||'b').testcase           := l_tc||'b';
      l_tc_aaTEST(l_tc||'b').asserts            := 3;
      l_tc_aaTEST(l_tc||'b').passes             := 2;
      l_tc_aaTEST(l_tc||'b').failures           := 1;
      --l_tc_aaTEST(l_tc||'b').errors             := null;
      l_tc_aaTEST(l_tc||'b').tot_interval_msecs := 300;
      --------------------------------------  WTPLSQL Testing --
      l_recTEST := l_recNULL;
      l_recTEST.test_run_id         := l_test_run_id;
      l_recTEST.asserts             := 6;
      l_recTEST.passes              := 4;
      l_recTEST.failures            := 2;
      --l_recTEST.errors              := null;
      l_recTEST.tot_interval_msecs  := 600;
      --------------------------------------  WTPLSQL Testing --
      l_recTEST.profiled_lines      := 20;
      l_recTEST.executed_lines      := 8;
      l_recTEST.ignored_lines       := 6;
      l_recTEST.excluded_lines      := 4;
      l_recTEST.notexec_lines       := 2;
      --l_recTEST.unknown_lines       := null;
      l_recTEST.tot_executed_usecs  := 2000;
      run_finalize('Run Finalize for Happy Path 2');
      --------------------------------------  WTPLSQL Testing --
      begin
         select * into l_tstat_rec
          from  wt_testcase_runs
          where test_run_id = l_test_run_id
           and  testcase    = l_tc||'a';
         l_sqlerrm := SQLERRM;
      exception when others then
         l_sqlerrm := SQLERRM;
      end;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'Retieve wt_testcase_runs record',
         check_this_in   => l_sqlerrm,
         against_this_in => 'ORA-0000: normal, successful completion');
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.test_run_id',
         check_this_in   => l_tstat_rec.test_run_id,
         against_this_in => l_test_run_id);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.testcase',
         check_this_in   => l_tstat_rec.testcase,
         against_this_in => l_tc||'a');
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.asserts',
         check_this_in   => l_tstat_rec.asserts,
         against_this_in => 3);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.passes',
         check_this_in   => l_tstat_rec.passes,
         against_this_in => 2);
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.failures',
         check_this_in   => l_tstat_rec.failures,
         against_this_in => 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.errors',
         check_this_in   => l_tstat_rec.errors,
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.test_yield',
         check_this_in   => l_tstat_rec.test_yield,
         against_this_in => 0.667);
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.avg_interval_msecs',
         check_this_in   => l_tstat_rec.avg_interval_msecs,
         against_this_in => 100);
      --------------------------------------  WTPLSQL Testing --
      begin
         select * into l_tstat_rec
          from  wt_testcase_runs
          where test_run_id = l_test_run_id
           and  testcase    = l_tc||'b';
         l_sqlerrm := SQLERRM;
      exception when others then
         l_sqlerrm := SQLERRM;
      end;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'Retieve wt_testcase_runs record',
         check_this_in   => l_sqlerrm,
         against_this_in => 'ORA-0000: normal, successful completion');
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.test_run_id',
         check_this_in   => l_tstat_rec.test_run_id,
         against_this_in => l_test_run_id);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.testcase',
         check_this_in   => l_tstat_rec.testcase,
         against_this_in => l_tc||'b');
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.asserts',
         check_this_in   => l_tstat_rec.asserts,
         against_this_in => 3);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.passes',
         check_this_in   => l_tstat_rec.passes,
         against_this_in => 2);
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.failures',
         check_this_in   => l_tstat_rec.failures,
         against_this_in => 1);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.errors',
         check_this_in   => l_tstat_rec.errors,
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.test_yield',
         check_this_in   => l_tstat_rec.test_yield,
         against_this_in => 0.667);
      wt_assert.eq (
         msg_in          => 'l_tstat_rec.avg_interval_msecs',
         check_this_in   => l_tstat_rec.avg_interval_msecs,
         against_this_in => 100);
      --------------------------------------  WTPLSQL Testing --
      begin
         select * into l_recTEST
          from  WT_TEST_RUN_STATS
          where test_run_id = l_test_run_id;
         l_sqlerrm := SQLERRM;
      exception when others then
         l_sqlerrm := SQLERRM;
      end;
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'Retieve WT_TEST_RUN_STATS record',
         check_this_in   => l_sqlerrm,
         against_this_in => 'ORA-0000: normal, successful completion');
      wt_assert.eq (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   => l_recTEST.test_run_id,
         against_this_in => l_test_run_id);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.test_yield',
         check_this_in   => l_recTEST.test_yield,
         against_this_in => 0.667);
      wt_assert.eq (
         msg_in          => 'l_recTEST.asserts',
         check_this_in   => l_recTEST.asserts,
         against_this_in => 6);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.passes',
         check_this_in   => l_recTEST.passes,
         against_this_in => 4);
      wt_assert.eq (
         msg_in          => 'l_recTEST.failures',
         check_this_in   => l_recTEST.failures,
         against_this_in => 2);
       --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.errors',
         check_this_in   => l_recTEST.errors,
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'l_recTEST.testcases',
         check_this_in   => l_recTEST.testcases,
         against_this_in => 2);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.avg_interval_msecs',
         check_this_in   => l_recTEST.avg_interval_msecs,
         against_this_in => 100);
      wt_assert.eq (
         msg_in          => 'l_recTEST.code_coverage',
         check_this_in   => l_recTEST.code_coverage,
         against_this_in => 0.8);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.profiled_lines',
         check_this_in   => l_recTEST.profiled_lines,
         against_this_in => 20);
      wt_assert.eq (
         msg_in          => 'l_recTEST.executed_lines',
         check_this_in   => l_recTEST.executed_lines,
         against_this_in => 8);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.ignored_lines',
         check_this_in   => l_recTEST.ignored_lines,
         against_this_in => 6);
      wt_assert.eq (
         msg_in          => 'l_recTEST.excluded_lines',
         check_this_in   => l_recTEST.excluded_lines,
         against_this_in => 4);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.eq (
         msg_in          => 'l_recTEST.notexec_lines',
         check_this_in   => l_recTEST.notexec_lines,
         against_this_in => 2);
      wt_assert.eq (
         msg_in          => 'l_recTEST.unknown_lines',
         check_this_in   => l_recTEST.unknown_lines,
         against_this_in => 0);
      wt_assert.eq (
         msg_in          => 'l_recTEST.avg_executed_usecs',
         check_this_in   => l_recTEST.avg_executed_usecs,
         against_this_in => 200);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.raises (
         msg_in         => 'Delete wt_testcase_runs Record',
         check_call_in  => 'delete from wt_testcase_runs where test_run_id = ' ||
                                                              l_test_run_id,
         against_exc_in => '');
      commit;
      wt_assert.eqqueryvalue (
         msg_in           => 'There should be no wt_testcase_runs records',
         check_query_in   => 'select count(*) from wt_testcase_runs' ||
                             ' where test_run_id = ' || l_test_run_id,
         against_value_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.raises (
         msg_in         => 'Delete WT_TEST_RUN_STATS Record',
         check_call_in  => 'delete from WT_TEST_RUN_STATS where test_run_id = ' ||
                                                              l_test_run_id,
         against_exc_in => '');
      commit;
      wt_assert.eqqueryvalue (
         msg_in           => 'There should be no WT_TEST_RUN_STATS records',
         check_query_in   => 'select count(*) from WT_TEST_RUN_STATS' ||
                             ' where test_run_id = ' || l_test_run_id,
         against_value_in => 0);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase  := 'FINALIZE Sad Path 1';
      l_tc_aaTEST.delete;
      l_recTEST := l_recNULL;
      l_recTEST.asserts := 2;
      run_finalize('Run Finalize for Sad Path 1');
      wt_assert.isnull (
         msg_in          => 'l_recTEST.test_run_id',
         check_this_in   => l_recTEST.test_run_id);
      wt_assert.isnull (
         msg_in          => 'l_recTEST.asserts',
         check_this_in   => l_recTEST.asserts);
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'FINALIZE Happy Path Teardown';
      wt_assert.raises (
         msg_in         => 'Delete WT_TEST_RUNS Record',
         check_call_in  => 'delete from WT_TEST_RUNS where id = ' ||
                                                l_test_run_id,
         against_exc_in => '');
      commit;
   end t_finalize;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


------------------------------------------------------------
procedure delete_records
      (in_test_run_id  in number)
is
begin
   delete from wt_testcase_runs
    where test_run_id = in_test_run_id;
   delete from wt_test_run_stats
    where test_run_id = in_test_run_id;
end delete_records;

$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure t_delete_records
   is
      l_test_run_id  number := -100;
      l_sql_txt      varchar2(4000);
   begin
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'Delete Records Happy Path Setup';
      l_sql_txt := 'insert into WT_TEST_RUNS' ||
                   ' (id, start_dtm, runner_owner, runner_name)' ||
         ' values (' || l_test_run_id || ', sysdate, USER, ''TESTRUNNER2'')';
      wt_assert.raises (
         msg_in         => 'Insert WT_TEST_RUNS Record',
         check_call_in  => l_sql_txt,
         against_exc_in => '');
      --------------------------------------  WTPLSQL Testing --
      l_sql_txt := 'insert into WT_TEST_RUN_STATS (test_run_id) values (' ||
                                                 l_test_run_id || ')';
      wt_assert.raises (
         msg_in         => 'Insert WT_TEST_RUN_STATS Record',
         check_call_in  => l_sql_txt,
         against_exc_in => '');
      l_sql_txt := 'insert into wt_testcase_runs (test_run_id, testcase)' ||
                   ' values (' || l_test_run_id || ', ''TESTCASE2'')';
      wt_assert.raises (
         msg_in         => 'Insert wt_testcase_runs Record',
         check_call_in  => l_sql_txt,
         against_exc_in => '');
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'Delete Records Happy Path and Teardown';
      wt_assert.raises (
         msg_in         => 'Delete Records with NULL ID',
         check_call_in  => 'begin wt_test_run_stat.delete_records(' ||
                                       l_test_run_id || '); end;',
         against_exc_in => '');
      wt_assert.raises (
         msg_in         => 'Delete WT_TEST_RUNS Record',
         check_call_in  => 'delete from WT_TEST_RUNS where id = ' || l_test_run_id,
         against_exc_in => '');
      --------------------------------------  WTPLSQL Testing --
      wt_assert.g_testcase := 'Delete Records Test Sad Paths';
      wt_assert.raises (
         msg_in         => 'Delete Records with NULL ID',
         check_call_in  => 'begin wt_test_run_stat.delete_records(null); end;',
         against_exc_in => '');
      wt_assert.raises (
         msg_in         => 'Delete Records with Invalid ID',
         check_call_in  => 'begin wt_test_run_stat.delete_records(-0.01); end;',
         against_exc_in => '');
   end t_delete_records;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------


--==============================================================--
$IF $$WTPLSQL_SELFTEST  ------%WTPLSQL_begin_ignore_lines%------
$THEN
   procedure WTPLSQL_RUN  --% WTPLSQL SET DBOUT "WT_TEST_RUN_STAT:PACKAGE BODY" %--
   is
   begin
      t_initialize;
      t_add_result;
      t_add_profile;
      t_finalize;
      t_delete_records;
   end WTPLSQL_RUN;
$END  ----------------%WTPLSQL_end_ignore_lines%----------------
--==============================================================--


end wt_test_run_stat;
