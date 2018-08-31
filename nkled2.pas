program nkled2;

var
  mystr : string[255];
  mynum : integer;
  I,J   : integer;
  LED   : array[0..7] of byte;

procedure scanner;
var
  SI,SJ   : integer;

begin
  SI := 0;
  for SJ := 1 to 10 do
  begin
    for SI := 0 to 7 do
    begin
      port[0] := LED[SI];
      delay(20);
    end;

    for SI := 7 downto 0 do
    begin
      port[0] := LED[SI];
      delay(20);
    end;
  end;
  for SI := 0 to 2 do
  begin
    port[0] := 255;
    delay(100);
    port[0] := 0;
    delay(100);
  end;
end;

procedure bcount;
var
  BI : byte;

begin
  for BI := 0 to 255 do
  begin
    port[0] := BI;
    delay(75);
  end;
end;

procedure randomled;
var
  R : byte;

begin
  R := random(255);
  writeln (R);
  port[0] := R;
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

  writeln('Nigel''s LED (port 0) writer. Written in Turbo Pascal.');
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
          then port[0] := mynum;
      end;
    end; {case}
  end;
  writeln('OK, bye!');
end.
