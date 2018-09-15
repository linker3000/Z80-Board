program nkled2;

var
  mystr : string[255];
  mynum : integer;
  I,J   : integer;
  LED   : array[0..7] of byte;
  ledport : integer;
  R     : real;

procedure scanner;
var
  SI,SJ   : integer;

begin
  SI := 0;
  for SJ := 1 to 10 do
  begin
    for SI := 0 to 7 do
    begin
      port[ledport] := LED[SI];
      delay(20);
    end;

    for SI := 7 downto 0 do
    begin
      port[ledport] := LED[SI];
      delay(20);
    end;
  end;
  for SI := 0 to 2 do
  begin
    port[ledport] := 255;
    delay(100);
    port[ledport] := 0;
    delay(100);
  end;
end;

procedure bcount;
var
  BI : byte;

begin
  for BI := 0 to 255 do
  begin
    port[ledport] := BI;
    delay(75);
  end;
end;

procedure randomled;
var
  R : byte;

begin
  R := random(255);
  writeln (R);
  port[ledport] := R;
end;


begin
  LED[0] := 1;
  LED[1] := 2;
  LED[2] := 4;
  LED[3] := 8;
  LED[4] := 16;
  LED[5] := 32;
  LED[6] := 64;
  LED[7] := 128;

  if ParamCount > 0 then
  begin
    val(ParamStr(1),R,I);
    if (R < 0.0) or (R > 32767.9) or (I <> 0) then ledport := 0
    else
      ledport := trunc(R);
  end
  else ledport := 8;

  writeln('Nigel''s LED writer. Written in Turbo Pascal.');
  writeln;
  writeln('Output port is defined as port[', ledport , '].');
  writeln('Specify a port number on the command line if you want to change it.');
  mystr := '0';
  mynum := 0;
  while mynum <> -1 do
  begin
    writeln;
    write ('Number 0-255, C for count, R for random, S for scanner or Q to quit : ');
    readln (mystr);

    case UpCase(mystr[1]) of
      'S' : scanner;
      'C' : bcount;
      'R' : randomled;
      'Q' : mynum := -1;
    else
      begin
        val (mystr,mynum,I);
        if (mynum > -1) and (mynum < 256)
          then port[8] := mynum;
      end;
    end; {case}
  end;
  writeln('OK, bye!');
end.

