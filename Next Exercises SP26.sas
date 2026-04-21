libname ipeds305 '~/IPEDS305';
options fmtsearch=(ipeds305);

proc sort data=ipeds305.gr2022;
  by ID Group;
run;

proc sort data=ipeds305.gr2021;
  by UnitID Group;
run;

data grads;
  set ipeds305.gr2023(in=in23) 
      ipeds305.gr2022(in=in22 rename=(ID=UnitID))
      ipeds305.gr2021(rename=(Total=grtotlt 
                              TotalMen=grtotlm
                              TotalWomen=grtotlw));
  by unitid;

  if in23 then Year=2023;
    else if in22 then Year=2022;
      else Year=2021;
  
  Graduates = grtotlt;
  Incoming = lag(grtotlt);
  GrRateTot = Graduates/Incoming;
  if find(put(group,chrtstat.),'Completers') then output;
  keep unitid Graduates Incoming GrRateTot year;
  format GrRateTot percentn8.2;
  label GrRateTot='Graduation Rate, All Students'
        Graduates='Number of Graduates'
        Incoming='Number in Incoming Cohort';
run;

data hdAll;
  set ipeds305.hd2021(in=in21 rename=(c21basic=cbasic))
      ipeds305.hd2022(in=in22 rename=(c21basic=cbasic ID=unitID Name=instnm state=stabbr))
      ipeds305.hd2023(rename=(c21basic=cbasic));
      
  if in21 then year = 2021;
    else if in22 then year = 2022;
      else year = 2023;
run;
  
proc sort data=hdAll;
  by unitid descending year;
run;

data SalAll;
  set ipeds305.sal2021(in=in21)
      ipeds305.sal2022(in=in22 rename=(ID=unitID))
      ipeds305.sal2023;
      
  if in21 then year = 2021;
    else if in22 then year = 2022;
      else year = 2023;
  avgSal=saoutlt/sainstt;
run;

proc sort data=SalAll;
  by unitid descending year;
run;

data all;
  merge grads(in=Keep) hdAll SalAll;
  by unitid descending year;
  if keep then output;
run; 

ods graphics / width=24cm height=12cm;
proc sgpanel data=all;
  styleattrs datacontrastcolors=(blue red cx00FF00)
            datasymbols=(circlefilled);
  where incoming ge 500;
  panelby year / columns=3 novarname;
  scatter x=GrRateTot y=avgSal / group=control;
  rowaxis label='Average Instructional Salary' valuesformat=dollar12.;
  colaxis values=(0 to 1 by .25);
  keylegend / title='';
run;