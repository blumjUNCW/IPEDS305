filename flw '/home/blumj/Documents/Cahoon/Northside Data 2005-2008.csv';
libname cahoon '/home/blumj/Documents/Cahoon';

data readIn;
  infile flw dsd firstobs=2;
  input date:mmddyy. flow rain temp hht;
  
  format date mmddyy10.;
run;

%let lags=14;
%macro tots;
data PreSetup;
  set readIn;
  array raintot(&lags);
  array rainL(&lags);
  array tempTot(&lags);
  array tempL(&lags);
  array HHTTot(&lags);
  array HHTL(&lags);
  
  
  %do l = 1 %to &lags;
    rainL(&l)=lag&l(rain);
    tempL(&l)=lag&l(temp);
    HHTL(&l)=lag&l(HHT);
    %if(&l eq 1) %then %do;
        raintot(&l) = rain;
        tempTot(&l) = temp;
        HHTtot(&l) = HHT;
    %end;
    %else %do;
      raintot(&l) = rain + %do k = 2 %to &l; %if(&k=&l) %then lag%eval(&k-1)(rain); %else lag%eval(&k-1)(rain) +; %end;;;
      tempTot(&l) = temp + %do k = 2 %to &l; %if(&k=&l) %then lag%eval(&k-1)(temp); %else lag%eval(&k-1)(temp) +; %end;;;
      HHTtot(&l) = HHT + %do k = 2 %to &l; %if(&k=&l) %then lag%eval(&k-1)(HHT); %else lag%eval(&k-1)(HHT) +; %end;;;
      raintot(&l) = raintot(&l)/&l;
      tempTot(&l) = tempTot(&l)/&l;
      HHTtot(&l) = HHTtot(&l)/&l;
    %end;
  %end;
run;
data setupPreInt;
  set PreSetup;
  array raintot(&lags);
  array raintotL(%eval(&lags/2));
  array rainL(&lags);
  array tempTot(&lags);
  array tempTotL(%eval(&lags/2));
  array tempL(&lags);
  array HHTTot(&lags);
  array HHTTotL(%eval(&lags/2));
  array HHTL(&lags);
  
  
  %do l = 1 %to %eval(&lags/2);
    rainTotL(&l)=rainTot(%eval(&l+1));
    tempTotL(&l)=tempTot(%eval(&l+1));
    HHTTotL(&l)=HHTTot(%eval(&l+1));
  %end;
run;

%mend;
options mprint;
%tots;

data cahoon.PreInt;
  set setupPreInt;
  treated='N';
run;

proc sgplot data=cahoon.PreInt;
  vbox HHTTot1 / discreteoffset=-0.25;
  vbox HHTTot14 / discreteoffset=0.25;
  *yaxis values=(1.0 to 1.8 by 0.2);
run;
proc means data=cahoon.PreInt  mean min q1 median q3 max std;;
  var HHTTot1 HHTTot14 flow;
run;
/*  */
/* proc corr data=setup; */
/*   with flow; */
/*   var HHTTot: HHTL:; */
/* ods select pearsoncorr; */
/* run; */
/* proc corr data=setup; */
/*   with flow; */
/*   var tempTot: tempL:; */
/* ods select pearsoncorr; */
/* run; */
/* proc corr data=setup; */
/*   with flow; */
/*   var rainTot: rainL:; */
/* ods select pearsoncorr; */
/* run; */

proc standard data=setupPreInt out=stdize mean=0 std=1;
  var raintot: tempTot: HHTtot:
      raintotL: tempTotL: HHTtotL:
      rainL: tempL: HHTL:
      ;
run;


%macro select;
proc glmselect data=stdize;
  model flow = %do l = 1 %to &lags; 
                %if(&l=&lags) %then raintot&l|tempTot&l|HHTtot&l|rainL&l|tempL&l|HHTL&l; 
                  %else raintot&l|tempTot&l|HHTtot&l|rainL&l|tempL&l|HHTL&l| ; 
              %end;
              @2 / cvmethod=block selection=stepwise(choose=cv) hierarchy=single;
run;
proc glmselect data=stdize;
  model flow = %do l = 1 %to &lags; 
                %if(&l=&lags) %then rainL&l|tempL&l|HHTL&l; 
                  %else rainL&l|tempL&l|HHTL&l| ; 
              %end;
              @2 / cvmethod=block selection=stepwise(choose=cv) hierarchy=single;
run;
proc glmselect data=stdize;
  model flow = %do l = 1 %to %eval(&lags/2); 
                %if(&l=%eval(&lags/2)) %then raintotL&l|tempTotL&l|HHTtotL&l; 
                  %else raintotL&l|tempTotL&l|HHTtotL&l| ; 
              %end;
              @2 / cvmethod=block selection=stepwise(choose=cv) hierarchy=single;
run;
%mend;
%select;


proc glmselect data=stdize;
  model flow =  raintot1|tempTot1|HHTtot1|raintot2|tempTot2|HHTtot2|raintot7|tempTot7|HHTtot7|raintot14|tempTot14|HHTtot14 
              @2 / cvmethod=block cvdetails=all selection=stepwise(choose=cv) hierarchy=single;
run;


proc glmselect data=stdize;
  model flow =  raintot1|tempTot1|HHTtot1|raintot2|tempTot2|HHTtot2|raintot7|tempTot7|HHTtot7|raintot14|tempTot14|HHTtot14 
              @2 / cvmethod=random cvdetails=all selection=stepwise(choose=cv) hierarchy=single;
run;

proc glmselect data=stdize;
  model flow =  raintot1|tempTot1|HHTtot1|raintot2|tempTot2|HHTtot2|raintot7|tempTot7|HHTtot7|raintot14|tempTot14|HHTtot14 
              @2 / cvmethod=split cvdetails=all selection=stepwise(choose=cv) hierarchy=single;
run;

