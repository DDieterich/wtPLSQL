[Demos and Examples](README.md)

# Test a PL/SQL Package

---

A majority of wtPLSQL testing is done with a Test Runner package.  In this example, we will create a Test Runner package that will test the DBMS_OUTPUT package.  The DBMS_OUTPUT package is a part of every Oracle database.  For brevity, only PUT_LINE and GET_LINE will be tested in the DBMS_OUTPUT package.

## Test Runner Package Specification

The specification for a Test Runner package is brutally simple.  It only needs one procedure.  Here, we create a package specification for the Test Runner.

Run this:

```
create or replace package test_dbms_output authid definer
as
   procedure wtplsql_run;
end test_dbms_output;
/
```

## Test Runner Package Body

Create a package body with the needed procedure.  Add a call to enable DBMS_OUTPUT for testing.  Setup and teardown will be handled later.

Run this:

```
create or replace package body test_dbms_output
as
   procedure wtplsql_run
   as
   begin
      dbms_output.enable(128000);
   end wtplsql_run;
end test_dbms_output;
/
```

## Testing Put Line and Get Line

The new TEST_PUT_GET_LINE procedure will test the PUT_LINE and GET_LINE procedures together.  Also, the TEST_PUT_GET_LINE procedure call is added to the WTPLSQL_RUN procedure.

Run this:

```
create or replace package body test_dbms_output
as
   procedure test_put_get_line
   is
      c_test1   constant varchar2(100) := 'Test 1';
      l_buffer  varchar2(4000) := '';
      l_status  number := null;
   begin
      dbms_output.put_line(c_test1);
      dbms_output.get_line(l_buffer,l_status);
      wt_assert.eq('Test 1',l_buffer,c_test1);
   end test_put_get_line;
   procedure wtplsql_run
   as
   begin
      dbms_output.enable(128000);
      test_put_get_line;
   end wtplsql_run;
end test_dbms_output;
/
```

Then, run this:

```
begin
   wtplsql.test_run('TEST_DBMS_OUTPUT');
   wt_persist_report.dbms_out(USER,'TEST_DBMS_OUTPUT',30);
end;
/
```

And get this:

<img src="images/Testing Put Line and Get Line.PNG" alt="Testing Put Line and Get Line Result">

A successful test.  Notice that the value of the C_TEST1 constant is displayed in the test result details.

## Catching an Exception

In the previous example, everything worked correctly.  Here is an example of GET_LINE not working.  For testing purposes, an exception will be thrown between the PUT_LINE and GET_LINE call.

Run this:

```
create or replace package body test_dbms_output
as
   procedure test_put_get_line
   is
      c_test1   constant varchar2(100) := 'Test 1';
      l_buffer  varchar2(4000) := '';
      l_status  number := null;
   begin
      dbms_output.put_line(c_test1);
      raise_application_error(-20000, 'Fault insertion exception');
      dbms_output.get_line(l_buffer,l_status);
      wt_assert.eq('Test 1',l_buffer,c_test1);
   end test_put_get_line;
   procedure wtplsql_run
   as
   begin
      dbms_output.enable(128000);
      test_put_get_line;
   end wtplsql_run;
end test_dbms_output;
/
```

Then, run this:

```
begin
   wtplsql.test_run('TEST_DBMS_OUTPUT');
end;
/
```

You might get this:

```
Test 1
```

Your results should include the above results, if DBMS_OUTPUT is enabled.  There may be addition results due to a different wtPSQL configuration.

Notice there was no exception raised.  wtPLSQL captured the exception and logged it.  Also, the value of C_TEST1 shows in the output.  It was left behind in the DBMS_OUTPUT buffer.

Run this:

```
begin
   wt_persist_report.dbms_out(USER,'TEST_DBMS_OUTPUT',30);
end;
/
```

And get this:

<img src="images/Leaving Something Behind.PNG" alt="Leaving Something Behind Result">

No assertions were run because of the exception.  The exception that was captured appears below the test results summary.

## Setup and Teardown

Setup and Teardown procedures are used to prepare for and cleanup from tests.  For DBMS_OUTPUT testing, the buffer needs to be preserved before testing starts.  After testing is complete, the original buffer contents need to be returned to the buffer.

Run this:

```
create or replace package body test_dbms_output
as
   -- Global variables to capture buffer contents
   g_buffer_contents_va  DBMSOUTPUT_LINESARRAY;
   g_num_lines           number;
   --
   procedure setup
   is
   begin
      -- Capture buffer contents
      dbms_output.get_lines(g_buffer_contents_va, g_num_lines);
   end setup;
   --
   procedure test_put_get_line
   is
      c_test1   constant varchar2(100) := 'Test 1';
      l_buffer  varchar2(4000) := '';
      l_status  number := null;
   begin
      dbms_output.put_line(c_test1);
      raise_application_error(-20000, 'Fault insertion exception');
      dbms_output.get_line(l_buffer,l_status);
      wt_assert.eq('Test 1',l_buffer,c_test1);
   end test_put_get_line;
   --
   procedure teardown
   is
      l_junk_va  DBMSOUTPUT_LINESARRAY;
      l_num      number;
   begin
      -- Clear buffer contents
      dbms_output.get_lines(l_junk_va, l_num);
      -- Restore the buffer
      for i in 1 .. g_num_lines
      loop
         dbms_output.put_line(g_buffer_contents_va(i));
      end loop;
   end teardown;
   --
   procedure wtplsql_run
   is
      l_error_message  varchar2(4000);
   begin
      dbms_output.enable(128000);
      dbms_output.put_line('This should be preserved.');
      setup;
      test_put_get_line;
      teardown;
   exception when others then
      l_error_message := substr(dbms_utility.format_error_stack ||
                                dbms_utility.format_error_backtrace,1,4000);
      teardown;
      raise_application_error(-20000, l_error_message);
   end wtplsql_run;
   --
end test_dbms_output;
/
```

The Test Runner package is quite large now.  To review, the Test Runner will
* Capture the current DBMS_OUPUT buffer.
* Run a procedure that adds to the DBMS_OUPUT buffer.
* Catch an exception raised by the procedure.
* Capture the error stack.
* Clear the current DBMS_OUPUT buffer.
* Restore the original DBMS_OUPUT buffer.

In order to ensure it is restoring the original DBMS_OUPUT buffer, the message "This should be preserved." is added to the buffer.  That message should be available after the Test Runner completes.

Run this:

```
begin
   wtplsql.test_run('TEST_DBMS_OUTPUT');
end;
/
```

And get this:

```
This should be preserved.
```

Excellent! The original DBMS_OUPUT buffer was preserved and the errant C_TEST1 value was removed.

Run this:

```
begin
   wt_persist_report.dbms_out(USER,'TEST_DBMS_OUTPUT',30);
end;
/
```

And get this:

<img src="images/Setup and Teardown.PNG" alt="Setup and Teardown Result">

The exception handler preserved the error stack before calling teardown.  Also, there is an extra "ORA-20000:" at the front of the error stack displayed, but all the error information is preserved.

These are all the basic tools needed to successfully create and run Test Runner packages in wtPLSQL.

---
[Demos and Examples](README.md)
