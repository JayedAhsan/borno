{
  =============================================================================
  *****************************************************************************
     The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is Avro Keyboard 5.

     The Initial Developer of the Original Code is Mehdi Hasan Khan (mhasan@omicronlab.com).
     Portions created by Jayed Ahsan Saad are Copyright (C) Jayed Ahsan Saad. All Rights Reserved.



  *****************************************************************************
  =============================================================================
}



{ COMPLETE TRANSFERING }

unit clsE2BCharBased;

interface

uses
  classes, sysutils, StrUtils, clsEnglishtoBangla, clsPhoneticRegExBuilder,
  Generics.Collections, clsAbbreviation;
	 //removed	 clsUnicodeToBijoy2000;

const
  Max_EnglishLength = 50;
  Max_RegExQueryLength = 5000;

type
  TPhoneticCache = record
    EStr: string;
    Results: TStringList;
  end;

		 // Skeleton of Class TE2BCharBased
type
  TE2BCharBased = class
  private
    RegExBuilder: TEnglishtoRegEx;
    Abbreviation: TAbbreviation;
			 //removed		Bijoy: TUnicodeToBijoy2000;

    BlockLast: boolean;
    WStringList: TStringList;
  //  Nstr: string;
    FAutoCorrect: boolean;
   // AICWDict: TDictionary<string, string>;

    DetermineZWNJ_ZWJ: string;
    PhoneticCache: array[1..Max_EnglishLength] of TPhoneticCache;
    procedure Fix_ZWNJ_ZWJ(var rList: TStringList);
    procedure ProcessSpace(var Block: boolean);
    procedure ParseAndSend;
    procedure ParseAndSendNow;
    procedure ProcessEnter(var Block: boolean);
    procedure DoBackspace(var Block: boolean);
    procedure MyProcessVKeyDown(const KeyCode: Integer; var Block: boolean; const var_IfShift: boolean; const var_ShiftPressedEx: boolean);
    procedure AddStr(const Str: string);

 {   procedure AIchoosenwordL;
    procedure SaveCandidateOptions;
    procedure AIchoosenwordU;}
    // Replaced with borno ai's choosen word feature;

    procedure AddToCache(const MiddleMain_T: string; var rList: TStringList);
    procedure AddSuffix(const MiddleMain_T: string; var rList: TStringList);
    procedure PadResults(const Starting_Ignoreable_T, Ending_Ignorable_T: string; var rList: TStringList);
    function EscapeSpecialCharacters(const inputT: string): string;
    procedure SetAutoCorrectEnabled(const Value: boolean);
    function GetAutoCorrectEnabled: boolean;
  public
 //   EStr: string;
    //   ManuallySelectedCandidate: boolean;
    constructor Create; // Initializer
    destructor Destroy; override; // Destructor
   // procedure CutText(const inputEStr: string; var outSIgnore: string; var outMidMain: string; var outEIgnore: string);
    function ProcessVKeyDown(const KeyCode: Integer; var Block: boolean): string;
    procedure ProcessVKeyUP(const KeyCode: Integer; var Block: boolean);
    procedure ResetDeadKey;
    procedure SelectCandidate(const Item: string);
					// Published
    property AutoCorrectEnabled: boolean read GetAutoCorrectEnabled write SetAutoCorrectEnabled;
  end;

var
  Parser: TEnglishToBangla;
  AIcwDict: TDictionary<string, string>;

implementation

uses
		// Keyboard Input Handler (NativeMethods)  Closed Source
  Keyboard,
	 // Virtual Key Consts Closed Source
  Vkeys,
  // uAutoCorrect replaced with Borno's PostCorrectionEx
  PostCorrectionEx,
       //Topbar some codes are re-written to match with avro Closed Source
  GUIBAR,
		// Layout Loader (Encoder and Decoder) Closed Source
  KBLayEncDec,
	 //	 Registry Entries Closed Source
  reg_RW,



 // uSimilarSort replaced with SortStr
  SortStr,

   //regex (NOT PCRE DELPHI WRAPPER) Closed Source
  pSearchREGEX,
	 //	 Directory,File Handler of Borno Closed Source
  File_IO,
  // Auto Completion Closed Source
  ACompletion,
 // Open Source
  BanglaChars,

    // AI Closed Source
  BornoAI,
  // Database Loader (NOT DISQLITE3) Closed Source
  DataDecoder;


{ TE2BCharBased }

{ =============================================================================== }

procedure TE2BCharBased.AddStr(const Str: string);
begin
  EStr := EStr + Str;

  ParseAndSend;

  if IsEasyTyping = 'true' then
    AutoCompex.DataUpdate(EStr)
  else
    AutoCompex.ChangeVisibility;

end;

{ =============================================================================== }

procedure TE2BCharBased.AddSuffix(const MiddleMain_T: string; var rList: TStringList);
var
  iLen, J, K: Integer;
  isSuffix: string;
  B_Suffix: string;
  TempList: TStringList;
begin
  iLen := Length(MiddleMain_T);
  rList.Sorted := True;
  rList.Duplicates := dupIgnore;

  if iLen >= 2 then
  begin
    TempList := TStringList.Create;
    for J := 2 to iLen do
    begin
      isSuffix := LowerCase(MidStr(MiddleMain_T, J, iLen));

      if suffix.TryGetValue(isSuffix, B_Suffix) then
      begin
        if PhoneticCache[iLen - Length(isSuffix)].Results.Count > 0 then
        begin
          for K := 0 to PhoneticCache[iLen - Length(isSuffix)].Results.Count - 1 do
          begin
            if IsVowel(RightStr(PhoneticCache[iLen - Length(isSuffix)].Results[K], 1)) and (IsKar(LeftStr(B_Suffix, 1))) then
            begin
              TempList.Add(PhoneticCache[iLen - Length(isSuffix)].Results[K] + b_Y + B_Suffix);
            end
            else
            begin
              if RightStr(PhoneticCache[iLen - Length(isSuffix)].Results[K], 1) = b_Khandatta then
                TempList.Add(MidStr(PhoneticCache[iLen - Length(isSuffix)].Results[K], 1, Length(PhoneticCache[iLen - Length(isSuffix)].Results[K]) - 1) + b_T + B_Suffix)
              else if RightStr(PhoneticCache[iLen - Length(isSuffix)].Results[K], 1) = b_Anushar then
                TempList.Add(MidStr(PhoneticCache[iLen - Length(isSuffix)].Results[K], 1, Length(PhoneticCache[iLen - Length(isSuffix)].Results[K]) - 1) + b_NGA + B_Suffix)
              else
                TempList.Add(PhoneticCache[iLen - Length(isSuffix)].Results[K] + B_Suffix);
            end;
          end;
        end;
      end;
    end;

    for J := 0 to TempList.Count - 1 do
    begin
      rList.Add(TempList[J]);
    end;

    TempList.Clear;
    FreeAndNil(TempList);
  end;
end;

{ =============================================================================== }

procedure TE2BCharBased.AddToCache(const MiddleMain_T: string; var rList: TStringList);
var
  iLen: Integer;
begin
  iLen := Length(MiddleMain_T);
  PhoneticCache[iLen].EStr := MiddleMain_T;
  PhoneticCache[iLen].Results.Clear;
  PhoneticCache[iLen].Results.Assign(rList);
end;

{ =============================================================================== }

constructor TE2BCharBased.Create;
var
  I: Integer;
begin
  inherited;
  Parser := TEnglishtoBangla.Create;
  Abbreviation := TAbbreviation.Create;
	//	 Bijoy := TUnicodeToBijoy2000.Create;
  RegExBuilder := TEnglishtoRegEx.Create;
  WStringList := TStringList.Create;
  AIcwDict := TDictionary<string, string>.Create;
  AIchoosenwordL;

  for I := Low(PhoneticCache) to High(PhoneticCache) do
  begin
    PhoneticCache[I].Results := TStringList.Create;
  end;

		 // If IsWinVistaOrLater Then
  DetermineZWNJ_ZWJ := ZWJ;
		 // Else
		 // DetermineZWNJ_ZWJ := ZWNJ;

end;

{ =============================================================================== }


{ =============================================================================== }

destructor TE2BCharBased.Destroy;
var
  I: Integer;
begin
  WStringList.Clear;
  FreeAndNil(WStringList);
	 //	 FreeAndNil(Bijoy);
  FreeAndNil(Parser);
  FreeAndNil(RegExBuilder);
  FreeAndNil(Abbreviation);
  if savechoosenword = 'true' then
    AIchoosenwordS;
  FreeAndNil(AIcwDict);

  for I := Low(PhoneticCache) to High(PhoneticCache) do
  begin
    PhoneticCache[I].Results.Clear;
    PhoneticCache[I].Results.Free;
  end;

  inherited;
end;

{ =============================================================================== }

procedure TE2BCharBased.DoBackspace(var Block: boolean);
var
  BijoyNstr: string;
begin

  if (Length(EStr) - 1) <= 0 then
  begin

			 //		If OutputIsBijoy <> 'true' Then Begin
    if (Length(Nstr) - 1) >= 1 then
      Backspace(Length(Nstr) - 1);
			 {		End
					Else Begin
							 BijoyNstr := Bijoy.Convert(Nstr);
							 If (Length(BijoyNstr) - 1) >= 1 Then
										Backspace(Length(BijoyNstr) - 1);
					End;   }

    ResetDeadKey;
    Block := False;
  end
  else if (Length(EStr) - 1) > 0 then
  begin
    Block := True;
    EStr := LeftStr(EStr, Length(EStr) - 1);
    ParseAndSend;
  end;

  if IsEasyTyping = 'true' then
  begin
    if EStr <> '' then
      AutoCompex.DataUpdate(EStr)
    else
      AutoCompex.ChangeVisibility;
  end
  else
    AutoCompex.ChangeVisibility;

end;

{ =============================================================================== }

function TE2BCharBased.EscapeSpecialCharacters(const inputT: string): string;
var
  T: string;
begin
  T := inputT;
  T := ReplaceStr(T, '\', '');
  T := ReplaceStr(T, '|', '');
  T := ReplaceStr(T, '(', '');
  T := ReplaceStr(T, ')', '');
  T := ReplaceStr(T, '[', '');
  T := ReplaceStr(T, ']', '');
  T := ReplaceStr(T, '{', '');
  T := ReplaceStr(T, '}', '');
  T := ReplaceStr(T, '^', '');
  T := ReplaceStr(T, '$', '');
  T := ReplaceStr(T, '*', '');
  T := ReplaceStr(T, '+', '');
  T := ReplaceStr(T, '?', '');
  T := ReplaceStr(T, '.', '');

		 // Additional characters
  T := ReplaceStr(T, '~', '');
  T := ReplaceStr(T, '!', '');
  T := ReplaceStr(T, '@', '');
  T := ReplaceStr(T, '#', '');
  T := ReplaceStr(T, '%', '');
  T := ReplaceStr(T, '&', '');
  T := ReplaceStr(T, '-', '');
  T := ReplaceStr(T, '_', '');
  T := ReplaceStr(T, '=', '');
  T := ReplaceStr(T, #39, '');
  T := ReplaceStr(T, '"', '');
  T := ReplaceStr(T, ';', '');
  T := ReplaceStr(T, '<', '');
  T := ReplaceStr(T, '>', '');
  T := ReplaceStr(T, '/', '');
  T := ReplaceStr(T, '\', '');
  T := ReplaceStr(T, ',', '');
  T := ReplaceStr(T, ':', '');
  T := ReplaceStr(T, '`', '');
  T := ReplaceStr(T, b_Taka, '');
  T := ReplaceStr(T, b_Dari, '');

  Result := T;

end;

{ =============================================================================== }

procedure TE2BCharBased.Fix_ZWNJ_ZWJ(var rList: TStringList);
var
  I: Integer;
  StartCounter, EndCounter: Integer;
begin
  StartCounter := 0;
  EndCounter := rList.Count - 1;

  if EndCounter <= 0 then
    exit;

  rList.Sorted := False;

  for I := StartCounter to EndCounter do
  begin
    rList[I] := ReplaceStr(rList[I], b_R + ZWNJ + b_Hasanta + b_Z, b_R + DetermineZWNJ_ZWJ + b_Hasanta + b_Z);
  end;
end;

{ =============================================================================== }

function TE2BCharBased.GetAutoCorrectEnabled: boolean;
begin
  Result := Parser.AutoCorrectEnabled;
end;

{ =============================================================================== }


{ =============================================================================== }

procedure TE2BCharBased.MyProcessVKeyDown(const KeyCode: Integer; var Block: boolean; const var_IfShift, var_ShiftPressedEx: boolean);
begin
  Block := False;
  case KeyCode of
    VK_DECIMAL:
      begin
        DECAI := true;
        AddStr('.');
        Block := True;
        exit;
      end;
    VK_DIVIDE:
      begin
        AddStr('/');
        Block := True;
        exit;
      end;
    VK_MULTIPLY:
      begin
        AddStr('*');
        Block := True;
        exit;
      end;
    VK_SUBTRACT:
      begin
        AddStr('-');
        Block := True;
        exit;
      end;
    VK_ADD:
      begin
        AddStr('+');
        Block := True;
        exit;
      end;

    VK_OEM_1:
      begin // key ;:
        if var_ShiftPressedEx = True then
          AddStr(':');
        if var_ShiftPressedEx = False then
          AddStr(';');
        Block := True;
        exit;
      end;
    VK_OEM_2:
      begin // key /?
        if var_ShiftPressedEx = True then
        begin
          AddStr('?');
          Block := True;
        end;

        if var_ShiftPressedEx = False then
        begin
          AddStr('/');
          Block := True;
        end;
        exit;
      end;

    VK_OEM_3:
      begin // key `~
        if var_ShiftPressedEx = True then
          AddStr('~');
        if var_ShiftPressedEx = False then
          AddStr('`');
        Block := True;
        exit;
      end;

    VK_OEM_4:
      begin // key [{
        if var_ShiftPressedEx = True then
          AddStr('{');
        if var_ShiftPressedEx = False then
          AddStr('[');
        Block := True;
        exit;
      end;

    VK_OEM_5:
      begin // key \|
        if var_ShiftPressedEx = True then
        begin
          if Dot = 'true' then
          begin
            DECAI := true;
            AddStr('.')
          end { New dot! }
          else
            AddStr('|');
        end;
        if var_ShiftPressedEx = False then
          AddStr('\');
        Block := True;
        exit;
      end;
    VK_OEM_6:
      begin // key ]}
        if var_ShiftPressedEx = True then
          AddStr('}');
        if var_ShiftPressedEx = False then
          AddStr(']');
        Block := True;
        exit;
      end;
    VK_OEM_7:
      begin // key '"
        if var_ShiftPressedEx = True then
          AddStr('"');
        if var_ShiftPressedEx = False then
          AddStr(#39);
        Block := True;
        exit;
      end;
    VK_OEM_COMMA:
      begin // key ,<
        if var_ShiftPressedEx = True then
          AddStr('<');
        if var_ShiftPressedEx = False then
          AddStr(',');
        Block := True;
        exit;
      end;
    VK_OEM_MINUS:
      begin // key - underscore
        if var_ShiftPressedEx = True then
          AddStr('_');
        if var_ShiftPressedEx = False then
          AddStr('-');
        Block := True;
        exit;
      end;
    VK_OEM_PERIOD:
      begin // key . >
        if var_ShiftPressedEx = True then
          AddStr('>');
        if var_ShiftPressedEx = False then
          AddStr('.');
        Block := True;
        exit;
      end;
    VK_OEM_PLUS:
      begin // key =+
        if var_ShiftPressedEx = True then
          AddStr('+');
        if var_ShiftPressedEx = False then
          AddStr('=');
        Block := True;
        exit;
      end;

    VK_0:
      begin
        if var_ShiftPressedEx = True then
          AddStr(')');
        if var_ShiftPressedEx = False then
          AddStr('0');
        Block := True;
        exit;
      end;
    VK_1:
      begin
        if var_ShiftPressedEx = True then
          AddStr('!');
        if var_ShiftPressedEx = False then
          AddStr('1');
        Block := True;
        exit;
      end;
    VK_2:
      begin
        if var_ShiftPressedEx = True then
          AddStr('@');
        if var_ShiftPressedEx = False then
          AddStr('2');
        Block := True;
        exit;
      end;
    VK_3:
      begin
        if var_ShiftPressedEx = True then
          AddStr('#');
        if var_ShiftPressedEx = False then
          AddStr('3');
        Block := True;
        exit;
      end;
    VK_4:
      begin
        if var_ShiftPressedEx = True then
          AddStr('$');
        if var_ShiftPressedEx = False then
          AddStr('4');
        Block := True;
        exit;
      end;
    VK_5:
      begin
        if var_ShiftPressedEx = True then
          AddStr('%');
        if var_ShiftPressedEx = False then
          AddStr('5');
        Block := True;
        exit;
      end;
    VK_6:
      begin
        if var_ShiftPressedEx = True then
          AddStr('^');
        if var_ShiftPressedEx = False then
          AddStr('6');
        Block := True;
        exit;
      end;
    VK_7:
      begin
        if var_ShiftPressedEx = True then
          AddStr('&');
        if var_ShiftPressedEx = False then
          AddStr('7');
        Block := True;
        exit;
      end;
    VK_8:
      begin
        if var_ShiftPressedEx = True then
          AddStr('*');
        if var_ShiftPressedEx = False then
          AddStr('8');
        Block := True;
        exit;
      end;
    VK_9:
      begin
        if var_ShiftPressedEx = True then
          AddStr('(');
        if var_ShiftPressedEx = False then
          AddStr('9');
        Block := True;
        exit;
      end;

    VK_NUMPAD0:
      begin
        AddStr('0');
        Block := True;
        exit;
      end;
    VK_NUMPAD1:
      begin
        AddStr('1');
        Block := True;
        exit;
      end;
    VK_NUMPAD2:
      begin
        AddStr('2');
        Block := True;
        exit;
      end;
    VK_NUMPAD3:
      begin
        AddStr('3');
        Block := True;
        exit;
      end;
    VK_NUMPAD4:
      begin
        AddStr('4');
        Block := True;
        exit;
      end;
    VK_NUMPAD5:
      begin
        AddStr('5');
        Block := True;
        exit;
      end;
    VK_NUMPAD6:
      begin
        AddStr('6');
        Block := True;
        exit;
      end;
    VK_NUMPAD7:
      begin
        AddStr('7');
        Block := True;
        exit;
      end;
    VK_NUMPAD8:
      begin
        AddStr('8');
        Block := True;
        exit;
      end;
    VK_NUMPAD9:
      begin
        AddStr('9');
        Block := True;
        exit;
      end;

    VK_A:
      begin
        if var_IfShift = True then
          AddStr('A');
        if var_IfShift = False then
          AddStr('a');
        Block := True;
        exit;
      end;
    VK_B:
      begin
        if var_IfShift = True then
          AddStr('B');
        if var_IfShift = False then
          AddStr('b');
        Block := True;
        exit;
      end;
    VK_C:
      begin
        if var_IfShift = True then
          AddStr('C');
        if var_IfShift = False then
          AddStr('c');
        Block := True;
        exit;
      end;
    VK_D:
      begin
        if var_IfShift = True then
          AddStr('D');
        if var_IfShift = False then
          AddStr('d');
        Block := True;
        exit;
      end;
    VK_E:
      begin
        if var_IfShift = True then
          AddStr('E');
        if var_IfShift = False then
          AddStr('e');
        Block := True;
        exit;
      end;
    VK_F:
      begin
        if var_IfShift = True then
          AddStr('F');
        if var_IfShift = False then
          AddStr('f');
        Block := True;
        exit;
      end;
    VK_G:
      begin
        if var_IfShift = True then
          AddStr('G');
        if var_IfShift = False then
          AddStr('g');
        Block := True;
        exit;
      end;
    VK_H:
      begin
        if var_IfShift = True then
          AddStr('H');
        if var_IfShift = False then
          AddStr('h');
        Block := True;
        exit;
      end;
    VK_I:
      begin
        if var_IfShift = True then
          AddStr('I');
        if var_IfShift = False then
          AddStr('i');
        Block := True;
        exit;
      end;
    VK_J:
      begin
        if var_IfShift = True then
          AddStr('J');
        if var_IfShift = False then
          AddStr('j');
        Block := True;
        exit;
      end;
    VK_K:
      begin
        if var_IfShift = True then
          AddStr('K');
        if var_IfShift = False then
          AddStr('k');
        Block := True;
        exit;
      end;
    VK_L:
      begin
        if var_IfShift = True then
          AddStr('L');
        if var_IfShift = False then
          AddStr('l');
        Block := True;
        exit;
      end;
    VK_M:
      begin
        if var_IfShift = True then
          AddStr('M');
        if var_IfShift = False then
          AddStr('m');
        Block := True;
        exit;
      end;
    VK_N:
      begin
        if var_IfShift = True then
          AddStr('N');
        if var_IfShift = False then
          AddStr('n');
        Block := True;
        exit;
      end;
    VK_O:
      begin
        if var_IfShift = True then
          AddStr('O');
        if var_IfShift = False then
          AddStr('o');
        Block := True;
        exit;
      end;
    VK_P:
      begin
        if var_IfShift = True then
          AddStr('P');
        if var_IfShift = False then
          AddStr('p');
        Block := True;
        exit;
      end;
    VK_Q:
      begin
        if var_IfShift = True then
          AddStr('Q');
        if var_IfShift = False then
          AddStr('q');
        Block := True;
        exit;
      end;
    VK_R:
      begin
        if var_IfShift = True then
          AddStr('R');
        if var_IfShift = False then
          AddStr('r');
        Block := True;
        exit;
      end;
    VK_S:
      begin
        if var_IfShift = True then
          AddStr('S');
        if var_IfShift = False then
          AddStr('s');
        Block := True;
        exit;
      end;
    VK_T:
      begin
        if var_IfShift = True then
          AddStr('T');
        if var_IfShift = False then
          AddStr('t');
        Block := True;
        exit;
      end;
    VK_U:
      begin
        if var_IfShift = True then
          AddStr('U');
        if var_IfShift = False then
          AddStr('u');
        Block := True;
        exit;
      end;
    VK_V:
      begin
        if var_IfShift = True then
          AddStr('V');
        if var_IfShift = False then
          AddStr('v');
        Block := True;
        exit;
      end;
    VK_W:
      begin
        if var_IfShift = True then
          AddStr('W');
        if var_IfShift = False then
          AddStr('w');
        Block := True;
        exit;
      end;
    VK_X:
      begin
        if var_IfShift = True then
          AddStr('X');
        if var_IfShift = False then
          AddStr('x');
        Block := True;
        exit;
      end;
    VK_Y:
      begin
        if var_IfShift = True then
          AddStr('Y');
        if var_IfShift = False then
          AddStr('y');
        Block := True;
        exit;
      end;
    VK_Z:
      begin
        if var_IfShift = True then
          AddStr('Z');
        if var_IfShift = False then
          AddStr('z');
        Block := True;
        exit;
      end;

					// Special cases-------------------->
      VK_HOME:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_END:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_PRIOR:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_NEXT:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_UP:
      begin
        if iseasytyping = 'true' then
        begin
          if (AutoCompex.DataOut.Count > 1) and (EStr <> '') then
          begin
            Block := True;
            AutoCompex.SelectPrevItem;
            AIchoosenwordU;
            exit;
          end;
        end
        else
        begin
          Block := False;
          ResetDeadKey;
          exit;
        end;
      end;
    VK_DOWN:
      begin
        if iseasytyping = 'true' then
        begin
          if (AutoCompex.DataOut.Count > 1) and (EStr <> '') then
          begin
            Block := True;
            AutoCompex.SelectNextItem;
            AIchoosenwordU;
            exit;
          end;
        end
        else
        begin
          Block := False;
          ResetDeadKey;
          exit;
        end;
      end;
    VK_RIGHT:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_LEFT:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_BACK:
      begin
        DoBackspace(Block);
        exit;
      end;
    VK_DELETE:
      begin
        Block := False;
        ResetDeadKey;
        exit;
      end;
    VK_ESCAPE:
      begin
        if (AutoCompex.PreviewWVisible = True) and (EStr <> '') then
        begin
          Block := True;
          ResetDeadKey;
          exit;
        end;
      end;

    VK_INSERT:
      begin
        Block := True;
        exit;
      end;
  end;
end;

{ =============================================================================== }

procedure TE2BCharBased.PadResults(const Starting_Ignoreable_T, Ending_Ignorable_T: string; var rList: TStringList);
var
  B_Starting_Ignoreable_T, B_Ending_Ignorable_T: string;
  I: Integer;
begin
  Parser.AutoCorrectEnabled := False;
  B_Starting_Ignoreable_T := Parser.Convert(Starting_Ignoreable_T);
  B_Ending_Ignorable_T := Parser.Convert(Ending_Ignorable_T);

  rList.Sorted := False;
  for I := 0 to rList.Count - 1 do
  begin
    rList[I] := B_Starting_Ignoreable_T + rList[I] + B_Ending_Ignorable_T;
  end;
end;

{ =============================================================================== }

procedure TE2BCharBased.ParseAndSend;
var
  I: Integer;
  RegExQuery: string;
  TempBanglaText1, TempBanglaText2: string;
  DictionaryFirstItem: string;
  Starting_Ignoreable_T, Middle_Main_T, Ending_Ignorable_T: string;
  AbbText, vasl: string;
  CandidateItem: string;
begin
  AutoCompex.DataOut.Items.Clear;

  Parser.AutoCorrectEnabled := True;
  TempBanglaText1 := Parser.Convert(EStr);
  Parser.AutoCorrectEnabled := False;
  TempBanglaText2 := Parser.Convert(EStr);

  if TempBanglaText1 = TempBanglaText2 then
    AutoCompex.DataOut.Items.Add(TempBanglaText1)
  else
  begin
					// If FAutoCorrect Then Begin
    AutoCompex.DataOut.Items.Add(TempBanglaText1);
    AutoCompex.DataOut.Items.Add(TempBanglaText2);
					// End
					// Else Begin
					// AutoCompex.List.Items.Add(TempBanglaText2);
					// AutoCompex.List.Items.Add(TempBanglaText1);
					// End;
  end;

  if (Pmode = 'normal') or (IsEasyTyping = 'false') then
  begin
    if (TempBanglaText1 <> TempBanglaText2) then
    begin
      if FAutoCorrect then
        AutoCompex.SelectItem(EscapeSpecialCharacters(TempBanglaText1))
      else
        AutoCompex.SelectItem(EscapeSpecialCharacters(TempBanglaText2));
    end
    else
      AutoCompex.SelectFirstItem;
  end
  else
  begin
   //CutText replaced with borno AI's StrInit ;
    StrInit(EStr, Starting_Ignoreable_T, Middle_Main_T, Ending_Ignorable_T);
    if (Length(Middle_Main_T) <= Max_EnglishLength) and (Length(Middle_Main_T) > 0) then
    begin

      WStringList.Clear;

      if Middle_Main_T = PhoneticCache[Length(Middle_Main_T)].EStr then
      begin
        WStringList.Assign(PhoneticCache[Length(Middle_Main_T)].Results);
        AddSuffix(Middle_Main_T, WStringList);
        SortStrEx(TempBanglaText2, WStringList);
        AbbText := '';
        AbbText := Abbreviation.CheckConvert(Middle_Main_T);
        if AbbText <> '' then
          WStringList.Add(AbbText);
        PadResults(Starting_Ignoreable_T, Ending_Ignorable_T, WStringList);
      end
      else
      begin
        RegExQuery := RegExBuilder.Convert(Middle_Main_T);
        CharSearch(Middle_Main_T, RegExQuery, WStringList);

        Fix_ZWNJ_ZWJ(WStringList);
        AddToCache(Middle_Main_T, WStringList);
        AddSuffix(Middle_Main_T, WStringList);
        SortStrEx(TempBanglaText2, WStringList);
        AbbText := '';
        AbbText := Abbreviation.CheckConvert(Middle_Main_T);
        if AbbText <> '' then
          WStringList.Add(AbbText);
        PadResults(Starting_Ignoreable_T, Ending_Ignorable_T, WStringList);
      end;

      if WStringList.Count > 0 then
        DictionaryFirstItem := WStringList[0];

      for I := 0 to WStringList.Count - 1 do
      begin
        if (WStringList[I] <> TempBanglaText1) and (WStringList[I] <> TempBanglaText2) then
          AutoCompex.DataOut.Items.Add(WStringList[I]);
      end;

							 //102318
      AutoCompex.SelectFirstItem;
               //AICWDict Replaced with AICWDict
      if AIcwDict.TryGetValue(Middle_Main_T, CandidateItem) and (Postcorrection = 'true') then
      begin
        AutoCompex.SelectItem(EscapeSpecialCharacters(CandidateItem));
      end
      else
      begin
        if WStringList.Count > 0 then
        begin
          if Length(Middle_Main_T) = 1 then
            AutoCompex.SelectFirstItem
          else
          begin
            if (TempBanglaText1 <> TempBanglaText2) then
            begin
              if FAutoCorrect then
                AutoCompex.SelectItem(EscapeSpecialCharacters(TempBanglaText1))
              else
              begin
                if Pmode = 'dictionary' then
                begin
                  if DictionaryFirstItem <> '' then
                    AutoCompex.SelectItem(EscapeSpecialCharacters(DictionaryFirstItem))
                  else
                    AutoCompex.SelectItem(EscapeSpecialCharacters(WStringList[0]));
                end
                else if Pmode = 'character' then
                begin
                  AutoCompex.SelectItem(EscapeSpecialCharacters(TempBanglaText2))
                end;
              end;
            end
            else
            begin
              if Pmode = 'dictionary' then
              begin
                if DictionaryFirstItem <> '' then
                  AutoCompex.SelectItem(EscapeSpecialCharacters(DictionaryFirstItem))
                else
                  AutoCompex.SelectItem(EscapeSpecialCharacters(WStringList[0]));
              end
              else if Pmode = 'character' then
              begin
                AutoCompex.SelectItem(EscapeSpecialCharacters(TempBanglaText2))
              end;
            end;
          end;
        end
        else
          AutoCompex.SelectFirstItem;
      end;
    end
    else
      AutoCompex.SelectFirstItem;

  //10/7/18
    if Mdict.TryGetValue(EStr, vasl) then
    begin
      if EStr.length > 1 then
        AutoCompex.DataOut.Items.Insert(1, UTF8ToUnicodeString(vasl))
      else
        AutoCompex.DataOut.Items.Insert(AutoCompex.DataOut.Items.count, UTF8ToUnicodeString(vasl));

    end;
  end;

  //frmprevW.ShowHideList;

  ManuallySelectedCandidate := False;
end;

{ =============================================================================== }

procedure TE2BCharBased.ParseAndSendNow;
var
  I, Matched, UnMatched: Integer;
  BijoyPstr, BijoyNstr: string;
begin
  Matched := 0;

	 //	 If OutputIsBijoy <> 'true' Then Begin
					{ Output to Unicode }
  if Pstr = '' then
  begin
           // Borno's SendKey Method;
    SendKey(Nstr);
						//	 SendKey_Char(Nstr);

    Pstr := Nstr;
  end
  else
  begin
    for I := 1 to Length(Pstr) do
    begin
      if MidStr(Pstr, I, 1) = MidStr(Nstr, I, 1) then
        Matched := Matched + 1
      else
        Break;
    end;
    UnMatched := Length(Pstr) - Matched;

    if UnMatched >= 1 then
      Backspace(UnMatched);
					 //		 SendKey_Char(MidStr(Nstr, Matched + 1, Length(Nstr)));
      // Borno's SendKey Method;
    SendKey(MidStr(Nstr, Matched + 1, Length(Nstr)));

    Pstr := Nstr;
  end;

	{	 End
		 Else Begin
					{ Output to Bijoy //
					BijoyPstr := Bijoy.Convert(Pstr);
					BijoyNstr := Bijoy.Convert(Nstr);

					If BijoyPstr = '' Then Begin
							 SendKey_Char(BijoyNstr);
							 Pstr := Nstr;
					End
					Else Begin
							 For I := 1 To Length(BijoyPstr) Do Begin
										If MidStr(BijoyPstr, I, 1) = MidStr(BijoyNstr, I, 1) Then
												 Matched := Matched + 1
										Else
												 Break;
							 End;
							 UnMatched := Length(BijoyPstr) - Matched;

							 If UnMatched >= 1 Then
										Backspace(UnMatched);
							 SendKey_Char(MidStr(BijoyNstr, Matched + 1, Length(BijoyNstr)));
							 Pstr := Nstr;
					End;

		 End;       }
end;

{ =============================================================================== }

procedure TE2BCharBased.ProcessEnter(var Block: boolean);
begin
  ResetDeadKey;
  Block := False;
end;

{ =============================================================================== }

procedure TE2BCharBased.ProcessSpace(var Block: boolean);
begin
  ResetDeadKey;
  Block := False;
end;

{ =============================================================================== }

function TE2BCharBased.ProcessVKeyDown(const KeyCode: Integer; var Block: boolean): string;
var
  m_Block: boolean;
begin
  m_Block := False;
  if (CtrlPressed = True) or (AltPressed = True) or (PressedWin = True) then
  begin
    Block := False;
    BlockLast := False;
    ProcessVKeyDown := '';
    exit;
  end;

  if (KeyCode = VK_SHIFT) or (KeyCode = VK_LSHIFT) or (KeyCode = VK_RSHIFT) then
  begin
    Block := False;
    BlockLast := False;
    ProcessVKeyDown := '';
    exit;
  end;
 if Topbar.GetEncoding = ASCII then
  begin

    Block := False;
    BlockLast := False;
    ProcessVKeyDown := '';
    exit;
  end
  else if Topbar.GetEncoding = UNICODE then
  begin

    if KeyCode = VK_SPACE then
    begin
      ProcessSpace(Block);
      ProcessVKeyDown := '';
      exit;
    end
    else if KeyCode = VK_TAB then
    begin
      if TabNavigation = 'true' then
      begin
        if iseasytyping = 'true' then
        begin
          if (AutoCompex.DataOut.Count > 1) and (EStr <> '') then
          begin
            Block := True;
            AutoCompex.SelectNextItem;
            AIchoosenwordU;
            exit;
          end
          else
          begin
            ResetDeadKey;
            Block := False;
            ProcessVKeyDown := '';
            exit;
          end;
        end;
      end
      else
      begin
        ResetDeadKey;
        Block := False;
        ProcessVKeyDown := '';
        exit;
      end;
    end
    else if KeyCode = VK_RETURN then
    begin
      ProcessEnter(Block);
      ProcessVKeyDown := '';
      exit;
    end
    else
    begin

      MyProcessVKeyDown(KeyCode, m_Block, ShiftPressed, ShiftPressedEx);
      ProcessVKeyDown := '';

      Block := m_Block;
      BlockLast := m_Block;
    end;
    if not AutoCompex.visible then
      AutoCompex.visible := true;

  end;

end;

{ =============================================================================== }

procedure TE2BCharBased.ProcessVKeyUP(const KeyCode: Integer; var Block: boolean);
begin
  if (KeyCode = VK_SHIFT) or (KeyCode = VK_RSHIFT) or (KeyCode = VK_LSHIFT) or (KeyCode = VK_LCONTROL) or (KeyCode = VK_RCONTROL) or (KeyCode = VK_CONTROL) or (KeyCode = VK_MENU) or (KeyCode = VK_LMENU) or (KeyCode = VK_RMENU) or (PressedWin = True) then
  begin
    Block := False;
    BlockLast := False;
    exit;
  end;
 if Topbar.GetEncoding = ASCII then
  begin

    Block := False;
    BlockLast := False;
  end
   else if Topbar.GetEncoding = UNICODE then
  begin

    if BlockLast = True then
      Block := True;
  end;
end;

{ =============================================================================== }

procedure TE2BCharBased.ResetDeadKey;
var
  I: Integer;
begin
  Pstr := '';
  EStr := '';
  BlockLast := False;
  Nstr := '';

  for I := Low(PhoneticCache) to High(PhoneticCache) do
  begin
    PhoneticCache[I].EStr := '';
    PhoneticCache[I].Results.Clear;
  end;

  if IsEasyTyping = 'true' then
    AutoCompex.ChangeVisibility;

end;

{ =============================================================================== }


{ =============================================================================== }

procedure TE2BCharBased.SelectCandidate(const Item: string);
begin
  Nstr := Item;
  ParseAndSendNow;
  ManuallySelectedCandidate := True;
end;

{ =============================================================================== }

procedure TE2BCharBased.SetAutoCorrectEnabled(const Value: boolean);
begin
  Parser.AutoCorrectEnabled := Value;
  FAutoCorrect := Value;
end;

{ =============================================================================== }

{ =============================================================================== }

end.

