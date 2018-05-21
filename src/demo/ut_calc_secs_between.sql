
/*file calc_secs_between.sp */
CREATE OR REPLACE PROCEDURE calc_secs_between (
   date1 IN DATE,
   date2 IN DATE,
   secs OUT NUMBER)
IS
BEGIN
   -- 24 hours in a day, 
   -- 60 minutes in an hour,
   -- 60 seconds in a minute...
   secs := (date2 - date1) * 24 * 60 * 60;
END;
/

CREATE OR REPLACE PACKAGE ut_calc_secs_between
IS
   -- For each program to test...
   PROCEDURE wtplsql_run;
END ut_calc_secs_between;
/

CREATE OR REPLACE PACKAGE BODY ut_calc_secs_between
IS

   --% WTPLSQL SET DBOUT "CALC_SECS_BETWEEN:PROCEDURE" %--

   -- For each program to test...
PROCEDURE wtplsql_run
IS
   secs PLS_INTEGER;
BEGIN
   CALC_SECS_BETWEEN (
         DATE1 => SYSDATE
         ,
         DATE2 => SYSDATE
         ,
         SECS => secs
    );

   utAssert.eq (
      'Same dates',
      secs, 
      0
      );
      
   CALC_SECS_BETWEEN (
         DATE1 => SYSDATE
         ,
         DATE2 => SYSDATE+1
         ,
         SECS => secs
    );

   utAssert.eq (
      'Exactly one day',
      secs, 
      24 * 60 * 60
      );
      
END wtplsql_run;

END ut_calc_secs_between;
/