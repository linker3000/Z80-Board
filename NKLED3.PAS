program nkled3;

var
  mystr : string[255];
  mynum : integer;
  I,J   : integer;
  LED   : array[0..11] of byte;
  ledport : integer;
  R     : real;

procedure blink (bl : integer);
var I : integer;

begin
  for I:= 1 to bl do
  begin
    port[ledport] := 255;
    delay(300);
    port[ledport] := 0;
    delay(300);
  end;
end;

procedure scanner(sfrom, sto : Byte);
var
  SI,SJ   : integer;

begin
  SI := 0;
  for SJ := 1 to 10 do
  begin
    for SI := sfrom to sto  do
    begin
      port[ledport] := LED[SI];
      delay(50);
    end;

    for SI := sto downto sfrom do
    begin
      port[ledport] := LED[SI];
      delay(50);
    end;
  end;
  blink(2);
end;

procedure flasher;
begin
  writeln ('Flashing: Press a key to stop');
  repeat
    blink(1);
  until keypressed;
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
  LED[8] := 129;
  LED[9] := 66;
  LED[10] := 36;
  LED[11] := 24;

  if ParamCount > 0 then
  begin
    val(ParamStr(1),R,I);
    if (R < 0.0) or (R > 32767.9) or (I <> 0) then ledport := 0
    else
      ledport := trunc(R);
  end
  else ledport := 0;

  writeln('Nigel''s LED writer V3. Written in Turbo Pascal.');
  writeln;
  writeln('Output port is defined as port[', ledport , '].');
  writeln('Specify a port number on the command line if you want to change it. ');
  mystr := '0';
  mynum := 0;
  while mynum <> -1 do
  begin
    writeln;
    write ('0-255, (C)ount, (B)ang, (F)lash, (R)nd, r(P)t rnd, (S)can or (Q)uit : ');
    readln (mystr);

    case UpCase(mystr[1]) of
      'B' : scanner(8,11);
      'S' : scanner(0,7);
      'C' : bcount;
      'F' : flasher;
      'R' : randomled;
      'P' : begin
              writeln ('Random numbers: Press a key to stop...');
              repeat
                randomled;
                delay(3000);
              until keypressed;
            end;
      'Q' : mynum := -1;
    else
      begin
        val (mystr,mynum,I);
        if (mynum > -1) and (mynum < 256)
          then port[ledport] := mynum;
      end;
    end; {case}
  end;
  writeln('OK, bye!');
  blink(3);
end.
