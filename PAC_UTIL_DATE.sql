CREATE OR REPLACE PACKAGE PAC_UTIL_DATE AS 

    function eastersunday(p_year number default to_number(to_char(sysdate,'RRRR')))  return date;
        /* source: https://whitehorsesblogarchive.wordpress.com/2010/05/13/ascension-today-plsql-algorithm-to-calculate-eastern-sunday/ */
    function get_similar_date(date_in in date default trunc(sysdate), p_days in int) return date;    

END PAC_UTIL_DATE;
/


CREATE OR REPLACE PACKAGE BODY PAC_UTIL_DATE AS

function eastersunday(p_year number default to_number(to_char(sysdate,'RRRR')))
  return date is
/*
||  Jan Thuis,   April 2004
||  Calculate the date of Easter Sunday
||
||  Gregorian method (any year since 1583) based on algorithm of Oudin
*/
  l_eastersunday date;
  l_g integer;
  l_c integer;
  l_d integer;
  l_e integer;
  l_h integer;
  l_k integer;
  l_p integer;
  l_q integer;
  l_i integer;
  l_j integer;
  l_x integer;

begin
  l_g := mod(p_year,19);
  l_c := floor(p_year/100);
  l_d := l_c - floor(l_c/4);
  l_e := floor((8 * l_c + 13)/25);
  l_h := mod(l_d - l_e + 19 * l_g + 15 ,30);
  l_k := floor(l_h / 28);
  l_p := floor(29/(l_h + 1));
  l_q := floor((21 - l_g)/11);
  l_i := l_h - l_k * (1 - l_k * l_p * l_q);
  l_j := mod((p_year + floor(p_year/4 + l_i + 2 - l_d )),7);
  l_x := 28 + l_i - l_j;
  l_eastersunday := to_date('0103'||p_year,'DDMMYYYY') + l_x -1;

  return l_eastersunday;
end eastersunday;

--------------------------------------------------------------------------------
function get_similar_date(date_in in date default trunc(sysdate), p_days in int) return date
is
/*
    Gabor Molnar 2024-06-26
    Looks for the similar day within P_DAYS range from DATE_IN
    In case of holidays looks for the next date with the same name
*/
    date_out date;
    
    date_easter_sunday date default (pac_util_date.eastersunday(to_number(to_char(date_in,'RRRR'))));
    date_easter_monday date default (pac_util_date.eastersunday(to_number(to_char(date_in,'RRRR'))) + 1);
    date_pentecost date default date_easter_monday + 49;
    
begin
    --date_out := date_in - 4 * 7; /*start from 4 weeks before -> same day, similar part of month, Thursday discounts will match etc....*/
    date_out := next_day(date_in-(/*4*7+1*/ p_days), to_char(date_in, 'DAY'));
    
    IF --date_out in (date_newyear, date_easter_sunday, date_easter_monday) /*if holiday - */
        to_char(date_out, 'yyyy-mm-dd') like '%-01-01' OR /*new year*/
        to_char(date_out, 'yyyy-mm-dd') like '%-03-15' OR /*hun - national day march15*/
        to_char(date_out, 'yyyy-mm-dd') like '%-05-01' OR /*Labour Day*/
        to_char(date_out, 'yyyy-mm-dd') like '%-08-20' OR /*hun - State Foundation day*/
        to_char(date_out, 'yyyy-mm-dd') like '%-10-23' OR /*hun - national day oct23*/
        to_char(date_out, 'yyyy-mm-dd') like '%-11-01' OR /*All Saints Day*/
        to_char(date_out, 'yyyy-mm-dd') like '%-12-25' OR /*Xmas day*/
        to_char(date_out, 'yyyy-mm-dd') like '%-12-26' OR /*Xmas day*/
        
        date_out in (date_easter_sunday, date_easter_monday, date_pentecost) /*easter sunday and monday*/
        THEN date_out := next_day(date_out, to_char(date_in, 'DAY')); /*rekurzio?*/
    END IF;
    
    
    
    return date_out;
end;  

--------------------------------------------------------------------------------
    
END PAC_UTIL_DATE;
/
