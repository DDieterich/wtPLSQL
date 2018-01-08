create or replace package body wt_profiler
as

   TYPE rec_type is record
      (test_run_id     wt_test_runs.id%TYPE
      ,dbout_owner     wt_test_runs.dbout_owner%TYPE
      ,dbout_name      wt_test_runs.dbout_name%TYPE
      ,dbout_type      wt_test_runs.dbout_type%TYPE
      ,prof_runid      binary_integer
      ,trigger_offset  binary_integer
      ,error_message   varchar2(4000));
   g_rec  rec_type;


----------------------
--  Private Procedures
----------------------

------------------------------------------------------------
-- Return DBMS_PROFILER specific error messages
function get_error_msg
      (retnum_in  in  binary_integer)
   return varchar2
is
   l_msg_prefix  varchar2(50) := 'DBMS_PROFILER Error: ';
begin
   case retnum_in
   when dbms_profiler.error_param then return l_msg_prefix ||
       'A subprogram was called with an incorrect parameter.';
   when dbms_profiler.error_io then return l_msg_prefix ||
       'Data flush operation failed.' ||
       ' Check whether the profiler tables have been created,' ||
       ' are accessible, and that there is adequate space.';
   when dbms_profiler.error_version then return l_msg_prefix ||
       'There is a mismatch between package and database implementation.' ||
       ' Oracle returns this error if an incorrect version of the' ||
       ' DBMS_PROFILER package is installed, and if the version of the' ||
       ' profiler package cannot work with this database version.';
   else return l_msg_prefix ||
       'Unknown error number ' || retnum_in;
   end case;
end get_error_msg;

------------------------------------------------------------
procedure delete_plsql_profiler_recs
      (in_runid  in number default null)
is
   PRAGMA AUTONOMOUS_TRANSACTION;
begin
   -- Remove Profiler data older than 7 days if RUNID is NULL
   for buff in (select runid from plsql_profiler_runs
                 where (    in_runid is null
                        and run_date < trunc(sysdate) - 7 )
                   or  (    in_runid is not null
                        and in_runid = runid)
           order by run_date, runid)
   loop
      delete from plsql_profiler_data
       where runid = buff.runid;
      delete from plsql_profiler_units
       where runid = buff.runid;
      delete from plsql_profiler_runs
       where runid = buff.runid;
   end loop;
   COMMIT;
end delete_plsql_profiler_recs;

------------------------------------------------------------
procedure reset_g_rec
is
   l_rec_NULL  rec_type;
begin
   g_rec := l_rec_NULL;
end reset_g_rec;

------------------------------------------------------------
procedure find_dbout
      (in_pkg_name  in  varchar2)
is

   C_HEAD_RE CONSTANT varchar2(30) := '--% WTPLSQL SET DBOUT "';
   C_MAIN_RE CONSTANT varchar2(30) := '[[:alnum:]._$#]+';
   C_TAIL_RE CONSTANT varchar2(30) := '" %--';
   --
   -- Head Regular Expression is
   --   '--% WTPLSQL SET DBOUT "' - literal string
   -- Main Regular Expression is
   --   '[[:alnum:]._$#]'         - Any alpha, numeric, ".", "_", "$", or "#" character
   --   +                         - One or more of the previous characters
   -- Tail Regular Expression is
   --   '" %--'                   - literal string
   --
   -- Note: Packages, Procedure, Functions, and Types are in the same namespace
   --       and cannot have the same names.  However, Triggers can have the same
   --       name as any of the other objects.  Results are unknown if a Trigger
   --       name is the same as a Package, Procedure, Function or Type name.
   --
   cursor c_annotation is
      select regexp_substr(src.text, C_HEAD_RE||C_MAIN_RE||C_TAIL_RE)  TEXT
       from  user_source  src
       where src.name = in_pkg_name
        and  src.type = 'PACKAGE BODY'
        and  regexp_like(src.text, C_HEAD_RE||C_MAIN_RE||C_TAIL_RE)
       order by src.line;
   l_target   varchar2(32000);
   l_pos      number;

begin

   open c_annotation;
   fetch c_annotation into l_target;
   if c_annotation%NOTFOUND
   then
      close c_annotation;
      return;
   end if;
   close c_annotation;

   -- Strip the Head Sub-String
   l_target := regexp_replace(SRCSTR      => l_target
                             ,PATTERN     => '^' || C_HEAD_RE
                             ,REPLACESTR  => ''
                             ,POSITION    => 1
                             ,OCCURRENCE  => 1);
   -- Strip the Tail Sub-String
   l_target := regexp_replace(SRCSTR      => l_target
                             ,PATTERN     => C_TAIL_RE || '$'
                             ,REPLACESTR  => ''
                             ,POSITION    => 1
                             ,OCCURRENCE  => 1);

   -- Locate the Owner/Name separator
   l_pos := instr(l_target,'.');
   begin
      select obj.owner
            ,obj.object_name
            ,obj.object_type
        into g_rec.dbout_owner
            ,g_rec.dbout_name
            ,g_rec.dbout_type
       from  all_objects  obj
       where obj.object_type in ('FUNCTION', 'PROCEDURE', 'PACKAGE BODY',
                                 'TYPE BODY', 'TRIGGER')
        and  (   (    l_pos = 0
                  and obj.owner       = USER
                  and obj.object_name = l_target  )
              OR (    l_pos = 1
                  and obj.owner       = USER
                  and obj.object_name = substr(l_target,2,512) )
              OR (    l_pos > 1
                  and obj.owner       = substr(l_target,1,l_pos-1)
                  and obj.object_name = substr(l_target,l_pos+1,512) ) )
        and  exists (
             select 'x' from all_source src
              where src.owner  = obj.owner
               and  src.name   = obj.object_name
               and  src.type   = obj.object_type );
   exception when NO_DATA_FOUND
   then
      g_rec.error_message := 'Unable to find Database Object "' ||
                              l_target || '". ';
   end;

end find_dbout;

------------------------------------------------------------
procedure insert_dbout_profile
is
   PRAGMA AUTONOMOUS_TRANSACTION;
begin

   insert into wt_dbout_profiles
      with q1 as (
      select src.line
            ,case
             when ne.text is not null           then 'EXCL'
             when     ppd.total_occur = 0
                  and ppd.total_time  = 0       then 'NOTX'
             when    (    ppd.total_occur  = 0
                      and ppd.total_time != 0 )
                  or (    ppd.total_occur != 0
                      and ppd.total_time  = 0 ) then 'UNKN'
                                                else 'EXEC'
             end                STATUS
            ,ppd.total_occur
            ,ppd.total_time
            ,ppd.min_time
            ,ppd.max_time
            ,src.text
       from  plsql_profiler_units ppu
             join plsql_profiler_data  ppd
                  on  ppd.unit_number = ppu.unit_number
                  and ppd.runid       = g_rec.prof_runid
             join all_source  src
                  on  src.line  = ppd.line# + g_rec.trigger_offset
                  and src.owner = g_rec.dbout_owner
                  and src.name  = g_rec.dbout_name
                  and src.type  = g_rec.dbout_type
        left join wt_not_executable ne
                  on  ne.text = src.text
       where ppu.unit_owner = g_rec.dbout_owner
        and  ppu.unit_name  = g_rec.dbout_name
        and  ppu.unit_type  = g_rec.dbout_type
        and  ppu.runid      = g_rec.prof_runid
      )
      select g_rec.test_run_id
            ,line
            ,status
            ,sum(total_occur)   TOTAL_OCCUR
            ,sum(total_time)    TOTAL_TIME
            ,min(min_time)      MIN_TIME
            ,max(max_time)      MAX_TIME
            ,text
       from q1
       group by line
            ,status
            ,text;
   COMMIT;

   -- Delete PLSQL Profiler also has it's own
   --   PRAGMA AUTONOMOUS_TRANSACTION and COMMIT;
   delete_plsql_profiler_recs(g_rec.prof_runid);

end insert_dbout_profile;

------------------------------------------------------------
procedure update_anno_status
is

   PRAGMA AUTONOMOUS_TRANSACTION;

   cursor c_find_begin is
      select line
            ,instr(text,'--%WTPLSQL_begin_ignore_lines%--') col
       from  all_source
       where owner = g_rec.dbout_owner
        and  name  = g_rec.dbout_name
        and  type  = g_rec.dbout_type
        and  text like '%--\%WTPLSQL_begin_ignore_lines\%--%' escape '\'
       order by line;
   buff_find_begin  c_find_begin%ROWTYPE;

   cursor c_find_end (in_line in number, in_col in number) is
      with q1 as (
      select line
            ,instr(text,'--%WTPLSQL_end_ignore_lines%--') col
       from  all_source
       where owner = g_rec.dbout_owner
        and  name  = g_rec.dbout_name
        and  type  = g_rec.dbout_type
        and  line >= in_line
        and  text like '%--\%WTPLSQL_end_ignore_lines\%--%' escape '\'
      )
      select line
            ,col
       from  q1
       where line > in_line
          or (    line = in_line
              and col  > in_col)
       order by line
            ,col;
   buff_find_end  c_find_end%ROWTYPE;

begin

   open c_find_begin;
   loop
      fetch c_find_begin into buff_find_begin;

      exit when c_find_begin%NOTFOUND;

      open c_find_end (buff_find_begin.line, buff_find_begin.col);
      fetch c_find_end into buff_find_end;
      if c_find_end%NOTFOUND
      then
         buff_find_end.line := NULL;
      end if;
      close c_find_end;

      update wt_dbout_profiles
        set  status = 'ANNO'
       where test_run_id = g_rec.test_run_id
        and  line >= buff_find_begin.line + g_rec.trigger_offset
        and  (   buff_find_end.line is NULL
              OR line <= buff_find_end.line + g_rec.trigger_offset );

      exit when buff_find_end.line is NULL;

   end loop;
   close c_find_begin;

   COMMIT;
   
end update_anno_status;


---------------------
--  Public Procedures
---------------------

------------------------------------------------------------
procedure initialize
      (in_test_run_id      in  number,
       in_runner_name      in  varchar2,
       out_dbout_owner     out varchar2,
       out_dbout_name      out varchar2,
       out_dbout_type      out varchar2,
       out_trigger_offset  out number,
       out_profiler_runid  out number)
is

   l_retnum       binary_integer;

begin

   out_dbout_owner := NULL;
   out_dbout_name  := NULL;
   out_dbout_type  := NULL;

   if in_test_run_id is null
   then
      raise_application_error  (-20000, 'i_test_run_id is null');
   end if;

   reset_g_rec;
   g_rec.test_run_id := in_test_run_id;

   find_dbout(in_pkg_name => in_runner_name);
   if g_rec.dbout_name is null
   then
      return;
   end if;
   out_dbout_owner    := g_rec.dbout_owner;
   out_dbout_name     := g_rec.dbout_name;
   out_dbout_type     := g_rec.dbout_type;
 
   g_rec.trigger_offset := wt_profiler.trigger_offset
                              (dbout_owner_in => g_rec.dbout_owner
                              ,dbout_name_in  => g_rec.dbout_name
                              ,dbout_type_in  => g_rec.dbout_type );
   out_trigger_offset := g_rec.trigger_offset;

   -- Make room for more data
   delete_plsql_profiler_recs;
   
   l_retnum := dbms_profiler.INTERNAL_VERSION_CHECK;
   if l_retnum <> 0 then
      --dbms_profiler.get_version(major_version, minor_version);
      raise_application_error(-20000,
         'dbms_profiler.INTERNAL_VERSION_CHECK returned: ' || get_error_msg(l_retnum));
   end if;
   -- This starts the PROFILER Running!!!
   l_retnum := dbms_profiler.START_PROFILER(run_number => g_rec.prof_runid);
   if l_retnum <> 0 then
      raise_application_error(-20000,
         'dbms_profiler.START_PROFILER returned: ' || get_error_msg(l_retnum));
   end if;
   out_profiler_runid := g_rec.prof_runid;

end initialize;

------------------------------------------------------------
-- Because this procedure is called to cleanup after erorrs,
--  it must be able to run multiple times without causing damage.
procedure finalize
is
begin

   if g_rec.dbout_name is null
   then
      return;
   end if;
   if g_rec.test_run_id is null
   then
      raise_application_error  (-20000, 'g_rec.test_run_id is null');
   end if;

   -- DBMS_PROFILER.FLUSH_DATA is included with DBMS_PROFILER.STOP_PROFILER
   dbms_profiler.STOP_PROFILER;

   insert_dbout_profile;

   update_anno_status;

   reset_g_rec;

end finalize;

------------------------------------------------------------
procedure pause
is
begin
   if g_rec.dbout_name is null
   then
      return;
   end if;
   dbms_profiler.pause_profiler;
end pause;

------------------------------------------------------------
procedure resume
is
begin
   if g_rec.dbout_name is null
   then
      return;
   end if;
   dbms_profiler.resume_profiler;
end resume;

------------------------------------------------------------
-- Find begining of PL/SQL Block in a Trigger
function trigger_offset
      (dbout_owner_in  in  varchar2
      ,dbout_name_in   in  varchar2
      ,dbout_type_in   in  varchar2)
   return number
is
begin
   if dbout_type_in != 'TRIGGER'
   then
      return 0;
   end if;
   for buff in (
      select line, text from all_source
       where owner = dbout_owner_in
        and  name  = dbout_name_in
        and  type  = 'TRIGGER'
      order by line )
   loop
      if regexp_instr(buff.text,
                      '(^declare$' ||
                      '|^declare[[:space:]]' ||
                      '|[[:space:]]declare$' ||
                      '|[[:space:]]declare[[:space:]])', 1, 1, 0, 'i') <> 0
         OR
         regexp_instr(buff.text,
                      '(^begin$' ||
                      '|^begin[[:space:]]' ||
                      '|[[:space:]]begin$' ||
                      '|[[:space:]]begin[[:space:]])', 1, 1, 0, 'i') <> 0 
      then
         return buff.line - 1;
      end if;
   end loop;
   return 0;
end trigger_offset;

------------------------------------------------------------
function calc_pct_coverage
      (in_test_run_id  in  number)
   return number
IS
BEGIN
   for buff in (
      select sum(case status when 'EXEC' then 1 else 0 end)    HITS
            ,sum(case status when 'NOTX' then 1 else 0 end)    MISSES
       from  wt_dbout_profiles  p
       where test_run_id = in_test_run_id  )
   loop
      if buff.hits + buff.misses = 0
      then
         return -1;
      else
         return round(100 * buff.hits / (buff.hits + buff.misses),2);
      end if;
   end loop;
   return null;
END calc_pct_coverage;

------------------------------------------------------------
procedure delete_records
      (in_test_run_id  in number)
is
   l_profiler_runid  number;
begin
   select profiler_runid into l_profiler_runid
    from wt_test_runs where id = in_test_run_id;
   delete_plsql_profiler_recs(l_profiler_runid);
   delete from wt_dbout_profiles
    where test_run_id = in_test_run_id;
exception
   when NO_DATA_FOUND
   then
      return;
end delete_records;

end wt_profiler;