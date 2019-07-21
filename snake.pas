program snake;

{$I- No I/O checking}
{$R- No range checking}
{$V- No string checking}

(*

  Snake game for CP/M-80 V2.2 and VTxx/ANSI terminal

  Original version (C) 2018, Karl A. Brokstad (www.z80.no)

  Turbo Pascal conversion and other mods with permission
     (C) 2018, linker3000 (linker3000-at-gmail-dot-com)

  V1.2T: 21-Jul 2019
         Corrected Y boundary max in putFood.

  V1.1T: 14-Oct-2018
         Command line switch -m (monochrome) suppresses all colour codes
         Version numbering detached from Karl A. Brokstad's original

  V23N:  24-Sep-2018 First public release
         Game map used for collision detection and food position
         generation - this takes out several long loops.

 
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*)

Type

  Str255 = string[255];

Const

  progVersion   : string[4] = '1.1T';
  borderChar    : char = '#';
  snakeHeadChar : char = 'O';
  snakeBodyChar : char = '#';

  xMax          : Byte = 80;
  yMax          : Byte = 25;

var
   snakeX   : array [1..100] of byte;
   snakeY   : array [1..100] of byte;
   gameGrid : array [2..80, 2..25] of byte; {Tracks snake body and tail}

   snakeBodyANSI : String[8];
   foodANSI      : String[8];
   snakeHeadANSI : String[8];
   borderANSI    : String[8];
   resetANSI     : String[4];
   msgANSI       : String[8];

   snakeHead, snakeTail, snakeLength : integer;

   I, level, score : integer;
   inp, dir        : char;
   X, Y            : byte;
   crash, escaped  : boolean;
   time            : integer;  {Game delay factor}
   food            : boolean;
   foodX, foodY, foodV : byte;

(* * * * * * * * * * writeCtr * * * * * * * * * *)

procedure writeCtr(Line : Byte; S : Str255);
{ Write a centered line of text}
Var
 I : Integer;

begin
  I := 40 - round(Length(S)/2);
  If I < 1 then I := 1;
  gotoxy(I,Line);
  write(S);
end;

(* * * * * * * * * * clrKbd * * * * * * * * * *)

procedure clrKbd; {Clear keyboard buffer}
begin
  repeat until (bdos(6,255)) = 0;
end;

(* * * * * * * * * * readKbd * * * * * * * * * *)

procedure readKbd; {Check for direction keys}
begin
  if keypressed then case upcase(chr(bdos(6,255))) of

      'Z','A' : dir  := 'L';    (* left *)
      'X','W' : dir  := 'U';    (* up *)
      'N','S' : dir  := 'D';    (* down *)
      'M','D' : dir  := 'R';    (* right *)
       '+'    : time := (time + 5) and 255;
       '-'    : begin
                  time := time - 5;
                  if time < 0 then time := 0;
                end;
       '#'    : escaped := true;
     end;
end;

(* * * * * * * * * conIn * * * * * * * * * * * *)

function conIn : char;
begin
   conIn := chr(bdos(6, 255)); (* SILENT READ CHARACTER *)
end;

(* * * * * * * * sDelay * * * * * * * * * * * * * *)

{A non-blocking-ish delay during which we check the keyboard}

procedure sDelay (D : integer);
var I : integer;

begin

  for I := 1 to D do
  begin
    Delay(1);
    readKbd;
  end;
end;

(* * * * * * * * * SPLASH SCREEN * * * * * * * * * * * *)

procedure SplashScreen;
begin
   clrscr;
   write (msgANSI);
   writeCtr( 4,'SNAKE '+progVersion+' by Linker3000');
   writeCtr( 5,'From the original by Karl A. Brokstad (www.Z80.no)');
   writeCtr( 7,'This program comes with ABSOLUTELY NO WARRANTY.');
   writeCtr( 9,'This is free software, and you are welcome to redistribute it');
   writeCtr(10,'under certain conditions - see GPLV2 license:');
   writeCtr(11,'https://www.gnu.org/licenses/gpl-2.0.html');
   writeCtr(13,'Requirements:');
   writeCtr(15,'80x25 ANSI/VT100 compatible console');
   if (msgANSI = '') then
     writeCtr(16,'(Monochrome mode was chosen by command line switch)')
   else
     writeCtr(16,'(Start program with -m switch to disable ANSI colors)');
   writeCtr(18,'Movement:');
   writeCtr(20,'Z = left, X = up, N = down, M = right OR use WASD keys');
   writeCtr(21,'# = Quit to here during game');
   writeCtr(23,'Press ENTER to START or Q to QUIT');
   repeat
     repeat until keypressed;
     inp := conIn;
     if ((inp = 'Q') or (inp = 'q')) then halt;
   until (inp = #13);
end;

(* Put down food *)
Procedure putFood;
begin
  (* food value 1-9 *)
  foodV := 1 + random(9);

  repeat {Find a new food location}
    readKbd;
    foodX := 3 + random(xMax-3);      {Stay within walls}
    foodY := 3 + random(yMax-4);
  until (gameGrid[foodX,foodY] = 0); {Don't put food down over snake}

  food := true;
  gotoXY(foodX,foodY); {Draw food}
  write(foodANSI, foodV ,resetANSI);
  gotoXY(1,1);
  readKbd;
end; {food}

(* * * * * * * * * DRAW SCREEN * * * * * * * * * * * *)

procedure DrawScreen;
var I : integer;
begin
   clrscr;
   write(borderANSI);

   for I:=1 to xMax do
   begin
     gotoXY(I,1);
     write(borderChar);
     gotoXY(I,yMax);
     write(borderChar);
   end;

   for I:=1 to yMax do
   begin
     gotoXY(1,I);
     write(borderChar);
     gotoXY(xMax,I);
     write(borderChar);
   end;

   write(resetANSI);
end;

(* * * * * * * * * * * * * * * * * * * * * * *)
(* * * * * * * * * * MAIN * * * * * * * * * * *)

begin

  snakeBodyANSI := #27'[40m';
  foodANSI      := #27'[33;40m'; {Yellow on black background}
  snakeHeadANSI := #27'[40m';
  borderANSI    := #27'[31;44m';
  resetANSI     := #27'[0m';     {Reset ANSI attributes}
  msgANSI       := #27'[33;40m';

  if (ParamCount > 0) and ((ParamStr(1) = '-m') or (ParamStr(1) = '-M')) then
  begin
    snakeBodyANSI := '';
    foodANSI      := '';
    snakeHeadANSI := '';
    borderANSI    := '';
    resetANSI     := '';
    msgANSI       := '';
  end;

  repeat
    randomize;
    SplashScreen;  (* show splash screen *)

(* * * * * * * * * INIT GAME * * * * * * * * *)

    escaped := false;
    crash   := false;
    score   := 1;
    level   := 1;
    time    := 100; (* delay time *)

(* * * * * * * * * GAME LOOP * * * * * * * * *)
    while (not escaped) and (not crash) do
    begin
      {Clear the object location grid}
      for Y := 2 to yMax do for X := 2 to xMax do gameGrid[X,Y] := 0;

      DrawScreen;

      snakeHead := 1;               (* first position *)
      snakeLength := 1;             (* length and last position *)
      snakeTail := 2;               (* position to erase snakeTail := snakeHead + snakeLength *)

      X := 39;                      (* position in middle of screen *)
      Y := 12;

      snakeX[snakeLength] := X;
      snakeY[snakeLength] := Y;

      score := score + snakeLength;    (* write level and score *)
      gotoXY(30,1);
      write(' LEVEL ',level,'  SCORE : ',score,' ');

      food := false;

      for I := 5 downto 0 do
      begin
        gotoXY(X,Y);
        write(I);
        delay(500);
      end;

      dir := 'R';

(* * * * * * * * * START GAME LEVEL  * * * * * * * * *)

      repeat {Game level}

        readKbd; {Check keyboard for input}

        case dir of        (* MOVE readKbd *)
          'L' : X:=X-1;    (* left *)
          'R' : X:=X+1;    (* right *)
          'D' : Y:=Y+1;    (* down *)
          'U' : Y:=Y-1;    (* up *)
        end;

(* Save snake position *)
(* PUSH snake positions down the line *)
(* Always use full array size to keep processing speed consistent *)

        for I := 100 downto 2 do
        begin
          readKbd; {Check keyboard for input}
          snakeX[I] := snakeX[I-1];
          snakeY[I] := snakeY[I-1];
        end;

        snakeX[snakeHead] := X;
        snakeY[snakeHead] := Y;

        gotoXY(snakeX[snakeHead],snakeY[snakeHead]);   (* Draw new head *)
        write (snakeHeadANSI,snakeHeadChar);

        if snakeLength > 1 then
        begin
          readKbd;
          gotoXY(snakeX[snakeHead+1],snakeY[snakeHead+1]);   (* Draw body *)
          gameGrid[snakeX[snakeHead+1],snakeY[snakeHead+1]] := 1; {Where the body is}
          write (snakeBodyANSI,snakeBodyChar);
        end;

        gotoXY(snakeX[snakeTail],snakeY[snakeTail]);   (* erase tail *)
        gameGrid[snakeX[snakeTail],snakeY[snakeTail]] := 0; {Remove tail from map}

        write (resetANSI,' ');
        gotoXY(1,1);

        if (food = false) then putFood; {Put down some food}

        {Test snake position}
        if (X < 2) or (X >= xMax)     {Snake crashes into wall or own body }
          or (Y < 2) or (Y >= yMax)
          or (gameGrid[X,Y] = 1) then crash := true;

        if (X = foodX) and (Y = foodY) then {Snake eats food }
        begin
          readKbd;
          snakeLength := snakeLength + foodV;
          food := false;
          snakeTail := snakeLength +1;
          score := score + (foodV * level);
          gotoXY(30,1);
          write(' LEVEL ',level,'  SCORE : ',score,' ');
          gotoXY(1,1);
          readKbd;
        end;

        sDelay(time);       (* delay *)

      until crash or escaped or (snakeLength > 99); {game level}

(* * * * * * * * * * END GAME * * * * * * * *)

      write(msgANSI);
      if (crash or escaped) then                        (* game over *)
        if crash then writeCtr(12,' YOU CRASHED ')
          else writeCtr(12,' YOU QUIT! ');

      if snakeLength > 99 then                 (* advance to next level *)
      begin
        level := level + 1;
        time := time - 10;
        if (time < 1) then time := 1;
        writeCtr(12,' YOU MADE IT TO THE NEXT LEVEL ');
      end;
      write (resetANSI);

      clrKbd;
      writeCtr(14,' PRESS ENTER ');
      repeat until conIn = #13;
    end {while}
  until false;

(* * * * * * * * * * FINISH  * * * * * * * *)

end.

