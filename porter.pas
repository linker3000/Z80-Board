program porter;                                                                                                        
                                                                                                                       
(*                                                                                                                     
   A program to output to a port (LEDs?) on a Z80 system.                                                              
                                                                                                                       
   Supports port output to a single address and can also                                                               
   setup and write to a Z80 PIO chip.                                                                                  
                                                                                                                       
   This version: 1.0 28 April 2019                                                                                     
                                                                                                                       
   Author: N. Kendrick (linker3000@gmail.com)                                                                          
                                                                                                                       
   Released into the public domain.                                                                                    
                                                                                                                       
   To the extent possible under law, the author has dedicated all                                                      
   copyright and relic domain worldwide. This software is distributed without                                          
   any warranty.                                                                                                       
                                                                                                                       
   You should have received a copy of the CC0 Public Domain Dedication                                                 
   along with this software. If not, see                                                                               
   http://creativecommons.org/publicdomain/zero/1.0/                                                                   
*)                                                                                                                     
                                                                                                                       
type                                                                                                                   
                                                                                                                       
  str255 = string[255];                                                                                                
  str8   = string[8];                                                                                                  
  str2   = string[2];                                                                                                  
                                                                                                                       
const                                                                                                                  
  descStr : str255 = 'Z80 port writer    V1.0 Linker3000 April 2019';                                                  
  hexC    : array[0..15] of char = '0123456789ABCDEF';                                                                 
                                                                                                                       
                               {Single bit and the Newton patterns...}                                                 
  LED     : array[0..11] of byte = (1,2,4,8,16,32,64,128,129,66,36,24);                                                
                                                                                                                       
var                                                                                                                    
  myStr      : str255;                                                                                                 
  myNum      : integer;                                                                                                
  dummy      : integer;                                                                                                
  I,J        : integer;                                                                                                
  portVal    : integer;                                                                                                
  speed      : integer;                                                                                                
  portAdd    : integer;                                                                                                
  screenMode : boolean;                                                                                                
  PIOBase    : integer;                                                                                                
  PIOMode    : boolean;                                                                                                
  PIOPort    : Byte;                                                                                                   
                                                                                                                       
procedure init;                                                                                                        
begin                                                                                                                  
  PIOBase    := 104;   {SC103 PIO board for RC2014 default = 104 = 0x68}                                               
  PIOMode    := false; {True if we're using PIO}                                                                       
  PIOPort    := 0;     {0 = Port A, 1 = Port B}                                                                        
  speed      := 50;    {Master speed delay}                                                                            
  portAdd    := 0;     {Default I/O port}                                                                              
  screenMode := true;  {Interactive menu mode (not cli only)}                                                          
end;                                                                                                                   
                                                                                                                       
procedure clrKbd; {Clear keyboard buffer}                                                                              
begin                                                                                                                  
  repeat until (bdos(6,255)) = 0;                                                                                      
end;                                                                                                                   
                                                                                                                       
function toBinary (value:integer): str8;                                                                               
var                                                                                                                    
  B : byte;                                                                                                            
  S : str8;                                                                                                            
                                                                                                                       
begin                                                                                                                  
  S := '';                                                                                                             
  for B := 0 to 7 do                                                                                                   
  begin                                                                                                                
    if (value and $80) = $80 then S := S + '1' else S := S + '0';                                                      
    value := value shl 1;                                                                                              
  end;                                                                                                                 
  toBinary := S;                                                                                                       
end;                                                                                                                   
                                                                                                                       
function toHex(value:integer; hexLen:integer): str255;                                                                 
var                                                                                                                    
  S : str8;                                                                                                            
  I : integer;                                                                                                         
                                                                                                                       
begin                                                                                                                  
  S[0] := chr(hexLen);                                                                                                 
  for I := hexLen downto 1 do                                                                                          
  begin                                                                                                                
    S[I] := hexC[value and $F];                                                                                        
    value := value shr 4;                                                                                              
  end;                                                                                                                 
  tohex := S;                                                                                                          
end;                                                                                                                   
                                                                                                                       
procedure initPIO (portNum : integer);                                                                                 
begin                                                                                                                  
  { PIO control port is at PIO base address + 2 + port number (0=A or 1=B) }                                           
  port[PIOBase+2+portNum] := 207; {Set port control mode - see PIO datasheet}                                          
  port[PIOBase+2+portNum] := 0;   {All pins set to output}                                                             
end;                                                                                                                   
                                                                                                                       
procedure showPortMode;                                                                                                
begin                                                                                                                  
  write('Output mode: ');                                                                                              
  if (PIOMode) then                                                                                                    
  begin                                                                                                                
    write ('Write to port ');                                                                                          
    if PIOPort = 0 then write ('A (0)') else write ('B (1)');                                                          
    writeln (' of PIO chip at base address ',PIOBase,' ($',ToHex(PIOBase,2),')');                                      
  end                                                                                                                  
  else writeln ('Port write to address ',portAdd, ' ($',toHex(portAdd,2),')');                                         
end;                                                                                                                   
                                                                                                                       
procedure setPortMode;                                                                                                 
var                                                                                                                    
  I : integer;                                                                                                         
  S : string[255];                                                                                                     
                                                                                                                       
begin                                                                                                                  
  repeat                                                                                                               
    clrscr;                                                                                                            
    showPortMode;                                                                                                      
    writeln;                                                                                                           
    writeln ('There are two modes of operation:');                                                                     
    writeln;                                                                                                           
    writeln ('Mode 0: Direct port - This mode writes directly to a port location.');                                   
    writeln ('Mode 1: PIO mode    - This mode writes to port A (0) or B (1) on a Z80 PIO chip.');                      
    writeln;                                                                                                           
    writeln;                                                                                                           
    write ('Enter the required mode (0 or 1) or press ENTER when done : ');                                            
    readln (S);                                                                                                        
    writeln;                                                                                                           
                                                                                                                       
    if (S <> '') then                                                                                                  
    begin                                                                                                              
      if S = '1' then PIOMode := true else PIOMode := false;                                                           
                                                                                                                       
      if PIOMode then                                                                                                  
      begin                                                                                                            
        writeln('Current PIO base address is ',PIOBase,' ($',toHex(PIObase,2),').');                                   
        writeln;                                                                                                       
        writeln (' - For the SC103 PIO board for the RC2014 system, the default is 104 ($68).');                       
        writeln;                                                                                                       
        writeln ('Specify new PIO base address in decimal or $hex (e.g. 104 or $68)');                                 
        write   ('or press ENTER for no change : ');                                                                   
        readln(S);                                                                                                     
        if (S <> '') then                                                                                              
        begin                                                                                                          
          val(S,I,dummy);                                                                                              
          PIOBase := abs(I);                                                                                           
        end;                                                                                                           
        writeln;                                                                                                       
        write('Currently selected PIO port is ');                                                                      
        if PIOPort = 0 then writeln ('A (0)') else writeln ('B (1)');                                                  
                                                                                                                       
        write ('Specify port A or port B, or press ENTER for no change : ');                                           
        readln(S);                                                                                                     
        if (S <> '') then                                                                                              
        begin                                                                                                          
          if upcase(S) = 'B' then PIOPort := 1 else PIOPort := 0;                                                      
        end;                                                                                                           
      end                                                                                                              
      else                                                                                                             
      begin                                                                                                            
        writeln('The current port address is ',portAdd, ' ($',toHex(portAdd,2),')');                                   
        writeln;                                                                                                       
        writeln (' - For an RC2014 Digital I/O board the default is 0.');                                              
        writeln;                                                                                                       
        writeln ('Enter the port address in decimal or $hex (e.g. 16 or $10), or');                                    
        write ('press ENTER for no change : ');                                                                        
        readln(S);                                                                                                     
        if (S <> '') then                                                                                              
        begin                                                                                                          
          val(S,I,dummy);                                                                                              
          portAdd := abs(I);                                                                                           
        end;                                                                                                           
      end;                                                                                                             
    end;                                                                                                               
  until (S = '');                                                                                                      
  if PIOMode then InitPIO(PIOPort);                                                                                    
end;                                                                                                                   
                                                                                                                       
procedure showPortVal (tPortVal : integer);                                                                            
begin                                                                                                                  
  if screenMode then gotoxy(0,4);                                                                                      
  write ('Port value : ');                                                                                             
  if (tPortVal > -1) then                                                                                              
  begin                                                                                                                
    if tPortVal < 100 then write ('0');                                                                                
    if tPortVal < 10 then write ('0');                                                                                 
    write (tPortVal,' ($', toHex(tPortVal,2),' ',toBinary(tPortVal),') ')                                              
  end                                                                                                                  
  else write ('Not defined yet');                                                                                      
  if not screenMode then write (chr(13));                                                                              
end;                                                                                                                   
                                                                                                                       
procedure setPortVal (tportVal : integer);                                                                             
begin                                                                                                                  
  portVal := tportVal; {Tracks the value sent to the port}                                                             
  if PIOMode then                                                                                                      
    port [PIObase + PIOPort] := portVal                                                                                
  else                                                                                                                 
    port[portAdd] := portVal;                                                                                          
  showPortVal(portVal);                                                                                                
end;                                                                                                                   
                                                                                                                       
procedure setSpeed;                                                                                                    
var                                                                                                                    
                                                                                                                       
  S : Str255;                                                                                                          
                                                                                                                       
begin                                                                                                                  
  repeat                                                                                                               
    clrscr;                                                                                                            
    writeln ('The speed value is currently : ',speed);                                                                 
    writeln;                                                                                                           
    writeln ('A lower value will speed up output writes, a higher value will');                                        
    writeln ('slow things down. The default value is 50.');                                                            
    writeln;                                                                                                           
    write   ('Type a new value or press ENTER when done : ');                                                          
    readln (S);                                                                                                        
    if (S <> '') then                                                                                                  
    begin                                                                                                              
      val(S,speed,dummy);                                                                                              
      speed := abs(speed);                                                                                             
    end;                                                                                                               
  until (S = '');                                                                                                      
end;                                                                                                                   
                                                                                                                       
procedure flash (fl : integer);                                                                                        
var I : integer;                                                                                                       
                                                                                                                       
begin                                                                                                                  
  I := 1;                                                                                                              
  repeat                                                                                                               
    setPortVal(255);                                                                                                   
    delay(speed*6);                                                                                                    
    setPortVal(0);                                                                                                     
    delay(speed*6);                                                                                                    
    I := I + 1;                                                                                                        
  until (I > fl) or keypressed;                                                                                        
end;                                                                                                                   
                                                                                                                       
procedure scanner(sFrom, sTo : Byte);                                                                                  
var                                                                                                                    
  I : integer;                                                                                                         
                                                                                                                       
begin                                                                                                                  
  repeat                                                                                                               
    I := 0;                                                                                                            
    for I := sFrom to sTo do                                                                                           
    begin                                                                                                              
      setPortVal(LED[I]);                                                                                              
      delay(speed);                                                                                                    
    end;                                                                                                               
                                                                                                                       
    if not keypressed then                                                                                             
    begin                                                                                                              
      for I := sTo downto sFrom do                                                                                     
      begin                                                                                                            
        setPortVal(LED[I]);                                                                                            
        delay(speed);                                                                                                  
      end;                                                                                                             
    end;                                                                                                               
  until keypressed;                                                                                                    
end;                                                                                                                   
                                                                                                                       
procedure bCountUp;                                                                                                    
var                                                                                                                    
  I : Integer;                                                                                                         
                                                                                                                       
begin                                                                                                                  
  I := 0;                                                                                                              
  repeat                                                                                                               
    setPortVal(I);                                                                                                     
    delay(round(speed * 1.5));                                                                                         
    I := I + 1;                                                                                                        
  until (I > 255) or keypressed;                                                                                       
end;                                                                                                                   
                                                                                                                       
procedure bCountDn;                                                                                                    
var                                                                                                                    
  I : Integer;                                                                                                         
                                                                                                                       
begin                                                                                                                  
  I := 255;                                                                                                            
  repeat                                                                                                               
    setPortVal(I);                                                                                                     
    delay(round(speed * 1.5));                                                                                         
    I := I - 1;                                                                                                        
  until (I < 0) or keypressed;                                                                                         
end;                                                                                                                   
                                                                                                                       
procedure randomPortVal;                                                                                               
begin                                                                                                                  
  setPortVal(random(255));                                                                                             
end;                                                                                                                   
                                                                                                                       
procedure topText;                                                                                                     
begin                                                                                                                  
  clrscr;                                                                                                              
                                                                                                                       
  writeln(DescStr);                                                                                                    
  writeln;                                                                                                             
  showPortVal(-1);                                                                                                     
  writeln;                                                                                                             
  writeln;                                                                                                             
  showportmode;                                                                                                        
  writeln;                                                                                                             
  writeln('To change port number or mode, press M');                                                                   
  writeln;                                                                                                             
end;                                                                                                                   
                                                                                                                       
Procedure helpPage;                                                                                                    
begin                                                                                                                  
  ClrScr;                                                                                                              
  writeln ('This program writes bytes to an I/O port or Z80 PIO port (A or B)');                                       
  writeln;                                                                                                             
  writeln ('You can specify the exact byte you want written, or use the menu');                                        
  writeln ('to choose a static or dynamic bit pattern.');                                                              
  writeln;                                                                                                             
  writeln ('Options also allow for the pattern speed to be adjusted and the');                                         
  writeln ('output mode to be changed between an I/O address and a Z80 PIO.');                                         
  writeln;                                                                                                             
  writeln ('You can also control this program on the command line as follows.');                                       
  writeln;                                                                                                             
  writeln ('<program_name> -H OR -Mmode -Aport# -P[a|b] -Snnn -V[value or letter]');                                   
  writeln;                                                                                                             
  writeln ('Where: -H prints this help.');                                                                             
  writeln ('       -M is output mode: 0 = Port, 1 = PIO. (If used must be the 1st option.)');                          
  writeln ('       -A is the IO port or PIO base address in decimal or $hex.');                                        
  writeln ('       -P is PIO port A or B (0 or 1).');                                                                  
  writeln ('       -Snnn is a speed number (50 is the default).');                                                     
  writeln ('       -V is the value to write OR a menu letter for a pattern.');                                         
  writeln ('          If a -V value is given, the program runs on the command');                                       
  writeln ('          line and does not start the interactive menu. If this option');                                  
  writeln ('          is used it must be the last one on the command line.');                                          
  writeln;                                                                                                             
  write ('Press any key to continue ');                                                                                
  repeat until keypressed;                                                                                             
  if screenMode then toptext;                                                                                          
end;                                                                                                                   
                                                                                                                       
procedure doAction (mChoice : str255);                                                                                 
begin                                                                                                                  
  if (mChoice <> '') then                                                                                              
  begin                                                                                                                
    if not screenMode then                                                                                             
    begin                                                                                                              
      writeln (descStr);                                                                                               
      writeln;                                                                                                         
      showPortMode;                                                                                                    
      writeln ('Action     : ',upCase(mChoice[1]),'    PRESS A KEY TO STOP');                                          
    end;                                                                                                               
                                                                                                                       
    case upCase(mChoice[1]) of                                                                                         
      'H' : helpPage;                                                                                                  
      'S' : begin                                                                                                      
              setSpeed;                                                                                                
              if screenMode then topText;                                                                              
            end;                                                                                                       
      'M' : begin                                                                                                      
              setPortMode;                                                                                             
              if screenMode then topText;                                                                              
            end;                                                                                                       
      'N' : scanner(8,11);                                                                                             
      'L' : scanner(0,7);                                                                                              
      'C' : bCountUp;                                                                                                  
      'W' : bCountDn;                                                                                                  
      'U' : repeat                                                                                                     
              bCountUp;                                                                                                
              if not keypressed then bCountDn;                                                                         
            until keypressed;                                                                                          
      'F' : repeat                                                                                                     
              flash(1);                                                                                                
            until keypressed;                                                                                          
      'R' : randomPortVal;                                                                                             
      'P' : repeat                                                                                                     
              randomPortVal;                                                                                           
              delay(round(speed * 60));                                                                                
            until keypressed;                                                                                          
      'Q' : myNum := -1;                                                                                               
      else                                                                                                             
      begin                                                                                                            
        val (mChoice,myNum,I);                                                                                         
        if (myNum > -1) and (myNum < 256)                                                                              
          then setPortVal(myNum);                                                                                      
       end;                                                                                                            
    end; {case}                                                                                                        
  end; {if}                                                                                                            
end;                                                                                                                   
                                                                                                                       
procedure doParams;                                                                                                    
var                                                                                                                    
  I,V  : integer;                                                                                                      
  C    : char;                                                                                                         
  S,S2 : str255;                                                                                                       
                                                                                                                       
begin                                                                                                                  
  screenMode := true; {Screen mode unless there's a -V parameter}                                                      
  for I := 1 to ParamCount do                                                                                          
  begin                                                                                                                
    S  := paramStr(I);                                                                                                 
    C  := upcase(S[2]);  {First char of param string after the -}                                                      
    S2 := copy(S,3,255); {Rest of parameter string}                                                                    
    val(S2,V,dummy);                                                                                                   
    V := abs(V);                                                                                                       
                                                                                                                       
    if ((S2 <> '') or (C = 'H')) then case C of                                                                        
      'H' : begin                                                                                                      
              screenMode := false;                                                                                     
              helpPage;                                                                                                
            end;                                                                                                       
                                                                                                                       
      'A' : if PIOMode then PIOBase := V else portAdd := V;                                                            
                                                                                                                       
      'M' : if (S2[1] = '0') then                                                                                      
            begin                                                                                                      
              PIOmode := false;                                                                                        
           end                                                                                                         
           else                                                                                                        
           begin                                                                                                       
             if (S2[1] = '1') then PIOmode := true;                                                                    
           end;                                                                                                        
                                                                                                                       
      'P' : if (S2[1] = 'B') or (S2[1] = '1') then PIOPort := 1 else PIOPort := 0;                                     
                                                                                                                       
      'S' : speed := V;                                                                                                
                                                                                                                       
      'V' : begin                                                                                                      
              screenMode := false;                                                                                     
              if upcase(S2[1]) in ['H','N','L','C','W','U','F','R','P'] then                                           
              begin                                                                                                    
                if (PIOMode and (upcase(S2[1]) <> 'H')) then InitPIO(PIOPort);                                         
                doAction(S2[1]);                                                                                       
              end                                                                                                      
              else if (V < 256) then                                                                                   
              begin                                                                                                    
                writeln (descStr);                                                                                     
                writeln;                                                                                               
                showPortMode;                                                                                          
                if PIOMode then InitPIO(PIOPort);                                                                      
                setPortVal(V);                                                                                         
              end;                                                                                                     
            end;                                                                                                       
      end; {case}                                                                                                      
  end; {begin}                                                                                                         
end;                                                                                                                   
                                                                                                                       
{Main loop...}                                                                                                         
begin                                                                                                                  
  init; {Set default output and other parameters}                                                                      
                                                                                                                       
  if (ParamCount > 0) then doParams; {Process command line}                                                            
                                                                                                                       
  If ScreenMode then {not doing command line mode so draw screen}                                                      
  begin                                                                                                                
    topText;                                                                                                           
                                                                                                                       
    myStr := '0';                                                                                                      
    myNum := 0;                                                                                                        
    if PIOMode then InitPIO(PIOPort);                                                                                  
  end                                                                                                                  
  else myNum := -1; {We're in CLI mode so nothing else to do/show}                                                     
                                                                                                                       
  while myNum <> -1 do                                                                                                 
  begin                                                                                                                
    if keypressed then clrKbd;                                                                                         
    gotoxy (0,13);                                                                                                     
    writeln ('What do you want to do');                                                                                
    writeln ('~~~~~~~~~~~~~~~~~~~~~~');                                                                                
    writeln;                                                                                                           
    writeln ('Change (S)peed  (C)ount up     Count do(W)n  (U)p/Down cycle');                                          
    writeln ('(N)ewton        (F)lash        (R)andom      re(P)eat random');                                          
    writeln ('(L)arson scan   (M)ode change  (H)elp        (Q)uit');                                                   
    writeln;                                                                                                           
    writeln ('Most sequences can be stopped by pressing a key.');                                                      
    writeln;                                                                                                           
    write   ('Enter a number 0-255 ($00-$FF) or a menu letter : ');                                                    
    clreol;                                                                                                            
    readln (myStr);                                                                                                    
                                                                                                                       
    doAction(myStr);                                                                                                   
  end;                                                                                                                 
end.                                                                                                                   

