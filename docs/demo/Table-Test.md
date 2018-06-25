[Demos and Examples](README.md)

# Test Table Constraints

---

The syntax diagram in Oracle's "Database SQL Language Reference" (11.2) gives the list of [constraints](https://docs.oracle.com/cd/E11882_01/server.112/e41084/clauses002.htm#CJAEDFIB) this way:

* Not Null
* Unique (Key)
* Primary Key
* References (Foreign Key)
* Check

Typical unit testing (or white box testing) does not include the testing of constraints.  In large part, these constraints are assumed to work without testing.  Confirmation of continued function of these constraints is a reason to test them.

## Table with Constraints

A table with constraints is needed for testing.  This table has several constraints

Run this:

```
create table table_test_tab
  (id     number        constraint table_test_tab_nn1 not null
  ,name   varchar2(10)  constraint table_test_tab_nn2 not null
  ,constraint table_test_tab_pk primary key (id)
  ,constraint table_test_tab_uk1 unique (name)
  ,constraint table_test_tab_ck1 check (name = upper(name))
  );
```

For brevity, the check constraint will be the only constraint tested.

## Test Runner

Create a simple test runner.

Run this:

```
create or replace package table_test_pkg authid definer
as
   procedure wtplsql_run;
end table_test_pkg;
/
```

The constraint being tested ensures the name is in upper case.  Testing of the constraint requires a modification of the data in the table.  The consequences of leaving this modified data after the test must be considered.  In this test, the data modification will not be preserved.

This test case will only test a happy path.

Run this:

```
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
```

## Check the results

Run this:

```
set serveroutput on size unlimited format word_wrapped

begin
   wtplsql.test_run('TRIGGER_TEST_PKG');
   wt_text_report.dbms_out(USER,'TRIGGER_TEST_PKG',30);
end;
/
```

And Get This:

```
    wtPLSQL 1.1.0 - Run ID 70: 23-Jun-2018 07:30:47 PM

  Test Results for WTP_DEMO.TABLE_TEST_PKG
       Total Test Cases:        1       Total Assertions:        2
  Minimum Interval msec:        0      Failed Assertions:        0
  Average Interval msec:      443       Error Assertions:        0
  Maximum Interval msec:      886             Test Yield:   100.00%
   Total Run Time (sec):      0.9

 - WTP_DEMO.TABLE_TEST_PKG Test Result Details (Test Run ID 70)
-----------------------------------------------------------
 ---- Test Case: Happy Path 1
 PASS  886ms Successful Insert. RAISES/THROWS - No exception was expected. Exception raised was "". Exception raised by: "insert into table_test_tab (id, name) values (1, 'TEST1')".
 PASS    0ms Confirm l_rec.name. EQ - Expected "TEST1" and got "TEST1"
```

This is report level 30, the most detailed level of reporting.  Starting from the top, we find the test runner executed 1 test case and 2 assertions.  All tests passed for a 100% yield.  There is no code coverage for the constraints.

This is not a complete test.  More test cases are needed to confirm other constraints and sad path .

---
[Demos and Examples](README.md)