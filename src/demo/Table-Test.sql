
drop table table_test_tab;

create table table_test_tab
  (id     number        constraint table_test_tab_nn1 not null
  ,name   varchar2(10)  constraint table_test_tab_nn2 not null
  ,constraint table_test_tab_pk primary key (id)
  ,constraint table_test_tab_uk1 unique (name)
  ,constraint table_test_tab_ck1 check (name = upper(name))
  );

grant all on table_test_tab to wtp;

create or replace package table_test_pkg authid definer
as
   procedure wtplsql_run;
end table_test_pkg;
/

create or replace package body table_test_pkg
as
   procedure t_happy_path_1
   is
      l_rec  table_test_tab%ROWTYPE; 
   begin
      wt_assert.g_testcase := 'Happy Path 1';
      wt_assert.raises (
         msg_in         => 'Successful Insert',
         check_call_in  => 'insert into table_test_tab (id, name) values (1, ''TEST1'')',
         against_exc_in => '');
      select * into l_rec from table_test_tab where id = 1;
      wt_assert.eq (
         msg_in          => 'Confirm l_rec.name',
         check_this_in   => l_rec.name,
         against_this_in => 'TEST1');
      rollback;
   end t_happy_path_1;
   procedure wtplsql_run is
   begin
      t_happy_path_1;
   end wtplsql_run;
end table_test_pkg;
/

set serveroutput on size unlimited format word_wrapped

begin
   wtplsql.test_run('TABLE_TEST_PKG');
   wt_text_report.dbms_out(USER,'TABLE_TEST_PKG',30);
end;
/