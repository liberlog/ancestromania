{*************************************************************}
{                                                             }
{       Borland Delphi Visual Component Library               }
{       InterBase Express core components                     }
{                                                             }
{       Copyright (c) 1998-2002 Borland Software Corporation  }
{                                                             }
{    Additional code created by Jeff Overcash and used        }
{    with permission.                                         }
{*************************************************************}
// AL2012 adaptations � --
unit IBScript;

interface

uses
  SysUtils, Classes, IBDatabase, IBCustomDataset, ibsql2, IBDatabaseInfo;

type

  TIBScript = class;

  TIBParseKind = (stmtDDL, stmtDML, stmtSET, stmtCONNECT, stmtDrop,
    stmtCREATE, stmtINPUT, stmtUNK, stmtEMPTY, stmtTERM, stmtERR,
    stmtCOMMIT, stmtROLLBACK, stmtReconnect, stmtRollbackSavePoint,
    stmtReleaseSavePoint, stmtStartSavepoint);

  TIBSQLParseError = procedure(Sender: TObject; Error: string; SQLText: string;
    LineIndex: Integer) of object;
  TIBSQLExecuteError = procedure(Sender: TObject; Error: string; SQLText:
    string;
    LineIndex: Integer; var Ignore: Boolean) of object;
  TIBSQLParseStmt = procedure(Sender: TObject; AKind: TIBParseKind; SQLText:
    string) of object;
  TIBScriptParamCheck = procedure(Sender: TIBScript; var Pause: Boolean) of
    object;

  TIBSQLParser = class(TComponent)
  private
    FOnError: TIBSQLParseError;
    FOnParse: TIBSQLParseStmt;
    FScript, FInput: TStrings;
    FTerminator: string;
    FPaused: Boolean;
    FFinished: Boolean;
    procedure SetScript(const Value: TStrings);
    procedure SetPaused(const Value: Boolean);
    { Private declarations }
  private
    FTokens: TStrings;
    FWork: string;
    ScriptIndex, LineIndex, ImportIndex: Integer;
    InInput: Boolean;

    //Get Tokens plus return the actual SQL to execute
    function TokenizeNextLine: string;
    // Return the Parse Kind for the Current tokenized statement
    function IsValidStatement: TIBParseKind;
    procedure RemoveComment;
    function AppendNextLine: Boolean;
    procedure LoadInput;
  protected
    { Protected declarations }
    procedure DoOnParse(AKind: TIBParseKind; SQLText: string); virtual;
    procedure DoOnError(Error: string; SQLText: string); virtual;
    procedure DoParser;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Parse;
    property CurrentLine: Integer read LineIndex;
    property CurrentTokens: TStrings read FTokens;
  published
    { Published declarations }
    property Finished: Boolean read FFinished;
    property Paused: Boolean read FPaused write SetPaused;
    property Script: TStrings read FScript write SetScript;
    property Terminator: string read FTerminator write FTerminator;
    property OnParse: TIBSQLParseStmt read FOnParse write FOnParse;
    property OnError: TIBSQLParseError read FOnError write FOnError;
  end;

  TIBScriptStats = class
  private
    FBuffers: int64;
    FReadIdx: int64;
    FWrites: int64;
    FFetches: int64;
    FSeqReads: int64;
    FReads: int64;
    FDeltaMem: int64;

    FStartBuffers: int64;
    FStartReadIdx: int64;
    FStartWrites: int64;
    FStartFetches: int64;
    FStartSeqReads: int64;
    FStartReads: int64;
    FStartingMem : Int64;

    FDatabase: TIBDatabase;

    FInfoStats : TIBDatabaseInfo;
    procedure SetDatabase(const Value: TIBDatabase);
    function AddStringValues( list : TStrings) : int64;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Clear;
    procedure Stop;

    property Database : TIBDatabase read FDatabase write SetDatabase;
    property Buffers : int64 read FBuffers;
    property Reads : int64 read FReads;
    property Writes : int64 read FWrites;
    property SeqReads : int64 read FSeqReads;
    property Fetches : int64 read FFetches;
    property ReadIdx : int64 read FReadIdx;
    property DeltaMem : int64 read FDeltaMem;
    property StartingMem : int64 read FStartingMem;
  end;


  TIBScript = class(TComponent)
  private
    FSQLParser: TIBSQLParser;
    FAutoDDL: Boolean;
    FStatsOn: boolean;
    FDataset: TIBDataset;
    FDatabase: TIBDatabase;
    FOnError: TIBSQLParseError;
    FOnParse: TIBSQLParseStmt;
    FDDLTransaction: TIBTransaction;
    FTransaction: TIBTransaction;
    FTerminator: string;
    FDDLQuery, FDMLQuery: TIBSQL;
    FContinue: Boolean;
    FOnExecuteError: TIBSQLExecuteError;
    FOnParamCheck: TIBScriptParamCheck;
    FValidate, FValidating: Boolean;
    FStats: TIBScriptStats;
    FSQLDialect : Integer;
    FCharSet : String;

    FCurrentStmt: TIBParseKind;
    FExecuting : Boolean;
    function GetPaused: Boolean;
    procedure SetPaused(const Value: Boolean);
    procedure SetTerminator(const Value: string);
    procedure SetupNewConnection;
    procedure SetDatabase(const Value: TIBDatabase);
    procedure SetTransaction(const Value: TIBTransaction);
    function StripQuote(const Text: string): string;
    function GetScript: TStrings;
    procedure SetScript(const Value: TStrings);
    function GetSQLParams: TIBXSQLDA;
    procedure SetStatsOn(const Value: boolean);
    function GetTokens: TStrings;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure DoDML(const Text: string); virtual;
    procedure DoDDL(const Text: string); virtual;
    procedure DoSET(const Text: string); virtual;
    procedure DoConnect(const SQLText: string); virtual;
    procedure DoCreate(const SQLText: string); virtual;
    procedure DoReconnect; virtual;
    procedure DropDatabase(const SQLText: string); virtual;

    procedure ParserError(Sender: TObject; Error, SQLText: string;
      LineIndex: Integer);
    procedure ParserParse(Sender: TObject; AKind: TIBParseKind;
      SQLText: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ValidateScript: Boolean;
    procedure ExecuteScript;
    function ParamByName(Idx : String) : TIBXSQLVAR;
    property Paused: Boolean read GetPaused write SetPaused;
    property Params: TIBXSQLDA read GetSQLParams;
    property Stats : TIBScriptStats read FStats;
    property CurrentTokens : TStrings read GetTokens;
    property Validating : Boolean read FValidating;
  published
    property AutoDDL: Boolean read FAutoDDL write FAutoDDL default true;
    property Dataset: TIBDataset read FDataset write FDataset;
    property Database: TIBDatabase read FDatabase write SetDatabase;
    property Transaction: TIBTransaction read FTransaction write SetTransaction;
    property Terminator: string read FTerminator write SetTerminator;
    property Script: TStrings read GetScript write SetScript;
    property Statistics: boolean read FStatsOn write SetStatsOn default true;
    property OnParse: TIBSQLParseStmt read FOnParse write FOnParse;
    property OnParseError: TIBSQLParseError read FOnError write FOnError;
    property OnExecuteError: TIBSQLExecuteError read FOnExecuteError write
      FOnExecuteError;
    property OnParamCheck: TIBScriptParamCheck read FOnParamCheck write
      FOnParamCheck;
  end;

implementation

uses IBUtils, IB, IBXConst;

const
  QUOTE = '''';
  DBL_QUOTE = '"';

{ TIBSQLParser }

function TIBSQLParser.AppendNextLine: Boolean;
var
  FStrings: TStrings;
  FIndex: ^Integer;
begin
  if (FInput.Count > ImportIndex) then
  begin
    InInput := true;
    FStrings := FInput;
    FIndex := @ImportIndex;
  end
  else
  begin
    InInput := false;
    FStrings := FScript;
    FIndex := @ScriptIndex;
  end;

  if FIndex^ = FStrings.Count then
    Result := false
  else
  begin
    Result := true;
    repeat
      FWork := FWork + CRLF + FStrings[FIndex^];
      Inc(FIndex^);
    until (FIndex^ = FStrings.Count) or
      (Trim(FWork) > '');
  end;
  if InInput and (Trim(FWork) = '') then
    AppendNextLine;
end;

constructor TIBSQLParser.Create(AOwner: TComponent);
begin
  inherited;
  FScript := TStringlistUTF8.Create;
  FTokens := TStringlistUTF8.Create;
  FInput := TStringlistUTF8.Create;
  ImportIndex := 0;
  FTerminator := ';';  {do not localize}
end;

destructor TIBSQLParser.Destroy;
begin
  FScript.Free;
  FTokens.Free;
  FInput.Free;
  inherited;
end;

procedure TIBSQLParser.DoOnError(Error, SQLText: string);
begin
  if Assigned(FOnError) then
    FOnError(Self, Error, SQLText, LineIndex);
end;

procedure TIBSQLParser.DoOnParse(AKind: TIBParseKind; SQLText: string);
begin
  if Assigned(FOnParse) then
    FOnParse(Self, AKind, SQLText);
end;

procedure TIBSQLParser.DoParser;
var
  Stmt: TIBParseKind;
  Statement: string;
  i: Integer;
begin
  while ((ScriptIndex < FScript.Count) or
    (Trim(FWork) > '') or
    (ImportIndex < FInput.Count)) and
    not FPaused do
  begin
    Statement := TokenizeNextLine;
    Stmt := IsValidStatement;
    case Stmt of
      stmtERR:
        DoOnError(SIBInvalidStatement, Statement);
      stmtTERM:
        begin
          DoOnParse(Stmt, FTokens[2]);
          FTerminator := FTokens[2];
        end;
      stmtINPUT:
        try
          LoadInput;
        except
          on E: Exception do
            DoOnError(E.Message, Statement);
        end;
      stmtEMPTY:
        Continue;
      stmtSET:
        begin
          Statement := '';
          for i := 1 to FTokens.Count - 1 do
            Statement := Statement + FTokens[i] + ' ';
          Statement := TrimRight(Statement);
          DoOnParse(Stmt, Statement);
        end;
    else
      DoOnParse(stmt, Statement);
    end;
  end;
end;

function TIBSQLParser.IsValidStatement: TIBParseKind;
var
  Token, Token1 : String;
begin
  if FTokens.Count = 0 then
  begin
    Result := stmtEmpty;
    Exit;
  end;
  Token := AnsiUpperCase(FTokens[0]);
  if Token = 'COMMIT' then  {do not localize}
  begin
    Result := stmtCOMMIT;
    exit;
  end;
  if Token = 'ROLLBACK' then   {do not localize}
  begin
    if FTokens.Count < 2 then
    begin
      Result := stmtROLLBACK;
      Exit;
    end
    else
    begin
      if //  This is the 'rollback to savepoint' form
         ((FTokens.Count = 4) and
          (FTokens[1] = 'TO') and   {do not localize}
          (FTokens[2] = 'SAVEPOINT')) or  {do not localize}
          //  This is the 'rollback work to savepoint' form
         ((FTokens.Count = 5) and {do not localize}
          (FTokens[2] = 'TO') and  {do not localize}
          (FTokens[3] = 'SAVEPOINT')) then  {do not localize}
      begin
        Result := stmtErr;
        exit;
      end;
      Result := stmtRollbackSavepoint;
      exit;
    end;
  end;
  if Token = 'RECONNECT' then  {do not localize}
  begin
    Result := stmtReconnect;
    Exit;
  end;
  if Token = 'SAVEPOINT' then {do not localize}
  begin
    Result := stmtStartSavepoint;
    exit;
  end;
  if FTokens.Count < 2 then
  begin
    Result := stmtERR;
    Exit;
  end;
  Token1 := AnsiUpperCase(FTokens[1]);
  if (Token = 'RELEASE') and (Token1 = 'SAVEPOINT') then  {do not localize}
  begin
    Result := stmtReleaseSavepoint;
    exit;
  end;
  if (Token = 'INSERT') or (Token = 'DELETE') or   {do not localize}
    (Token = 'SELECT') or (Token = 'UPDATE') or    {do not localize}
    (Token = 'COMMENT') or                         {do not localize}//AL2012
    (Token = 'EXECUTE') or                         {do not localize}
    ((Token = 'EXECUTE') and (Token1 = 'PROCEDURE')) then  {do not localize} //? inutille d�j� satisfait par le pr�c�dent test Token='EXECUTE'
    Result := stmtDML
  else
    if Token = 'INPUT' then         {do not localize}
      Result := stmtINPUT
    else
      if Token = 'CONNECT' then         {do not localize}
        Result := stmtCONNECT
      else
        if (Token = 'CREATE') and
          ((Token1 = 'DATABASE') or (Token1 = 'SCHEMA')) then   {do not localize}
          Result := stmtCREATE
        else
          if (Token = 'DROP') and (Token1 = 'DATABASE') then    {do not localize}
            Result := stmtDROP
          else
            if (Token = 'DECLARE') or (Token = 'CREATE') or (Token = 'ALTER') or {do not localize}
              (Token = 'GRANT') or (Token = 'REVOKE') or (Token = 'DROP') or        {do not localize}
              ((Token = 'SET') and ((Token1 = 'GENERATOR'))) then  {do not localize}
              Result := stmtDDL
            else
              if (Token = 'SET') then       {do not localize}
              begin
                if (Token1 = 'TERM') then     {do not localize}
                  if FTokens.Count = 3 then
                    Result := stmtTERM
                  else
                    Result := stmtERR
                else
                  if (Token1 = 'SQL') then  {do not localize}
                     if (FTokens.Count = 4) and
                        (AnsiUpperCase(FTokens[2]) = 'DIALECT') then  {do not localize}
                       Result := stmtSET
                     else
                       Result := stmtERR
                  else
                    if (Token1 = 'AUTODDL') or (Token1 = 'STATISTICS') or  {do not localize}
                       (Token1 = 'NAMES') then {do not localize}
                      if FTokens.Count = 3 then
                        Result := stmtSET
                      else
                        Result := stmtERR
                    else
                      Result := stmtERR;
              end
              else
                Result := stmtERR;
end;

procedure TIBSQLParser.LoadInput;
var
  FileName: string;
begin
  FInput.Clear;
  ImportIndex := 0;
  FileName := FTokens[1];
  if FileName[1] in [QUOTE, DBL_QUOTE] then
    Delete(FileName, 1, 1);
  if FileName[Length(FileName)] in [QUOTE, DBL_QUOTE] then
    Delete(FileName, Length(FileName), 1);

  FInput.LoadFromFile(FileName);
end;

procedure TIBSQLParser.Parse;
begin
  ScriptIndex := 0;
  ImportIndex := 0;
  FInput.Clear;
  FPaused := false;
  DoParser;
end;

procedure TIBSQLParser.RemoveComment; //AL2012 ajout �limination lignes --
var
  Start, Ending: Integer;
begin
  FWork := TrimLeft(FWork);
  while (AnsiPos('/*', FWork)=1)or(AnsiPos('--', FWork)=1) do
  begin
    Start := AnsiPos('/*', FWork);    {do not localize}
    while Start = 1 do
    begin
      Ending := AnsiPos('*/', FWork); {do not localize}
      while Ending < Start do
      begin
        if AppendNextLine = false then
          raise Exception.Create(SIBInvalidComment);
        Ending := AnsiPos('*/', FWork);    {do not localize}
      end;
      Delete(FWork, 1, Ending + 1);
      FWork := TrimLeft(FWork);
      if FWork = '' then
        AppendNextLine;
      FWork := TrimLeft(FWork);
      Start := AnsiPos('/*', FWork);    {do not localize}
    end;
    Start := AnsiPos('--', FWork);    {do not localize}
    while Start = 1 do
    begin
      FWork := '';
      AppendNextLine;
      FWork := TrimLeft(FWork);
      Start := AnsiPos('--', FWork);    {do not localize}
    end;
  end;
end;

procedure TIBSQLParser.SetPaused(const Value: Boolean);
begin
  if FPaused <> Value then
  begin
    FPaused := Value;
    if not FPaused then
      DoParser;
  end;
end;

procedure TIBSQLParser.SetScript(const Value: TStrings);
begin
  FScript.Assign(Value);
  FPaused := false;
  ScriptIndex := 0;
  ImportIndex := 0;
  FInput.Clear;
end;

{ Note on TokenizeNextLine.  This is not intended to actually tokenize in
  terms of SQL tokens.  It has two goals.  First is to get the primary statement
  type in FTokens[0].  These are items like SELECT, UPDATE, CREATE, SET, IMPORT.
  The secondary function is to correctly find the end of a statement.  So if the
  terminator is ; and the statement is "SELECT 'FDR'';' from Table1;" while
  correct SQL tokenization is SELECT, 'FDR'';', FROM, Table1 but this is more
  than needed.  The Tokenizer will tokenize this as SELECT, 'FDR', ';', FROM,
  Table1.  We get that it is a SELECT statement and get the correct termination
  and whole statement in the case where the terminator is embedded inside
  a ' or ". }

function TIBSQLParser.TokenizeNextLine: string;
var
  InQuote, InDouble, InComment, InSpecial, Done: Boolean;
  NextWord: string;
  Index: Integer;

  procedure ScanToken;
  var
    SDone: Boolean;
  begin
    NextWord := '';
    SDone := false;
    Index := 1;
    while (Index <= Length(FWork)) and (not SDone) do
    begin
      { Hit the terminator, but it is not embedded in a single or double quote
          or inside a comment }
      if ((not InQuote) and (not InDouble) and (not InComment)) and
        (((CompareStr(FTerminator, Copy(FWork, Index, Length(FTerminator))) = 0) and
          (not InSpecial)) or
         (InSpecial and
          (FTokens.Count > 1) and
          (AnsiUpperCase(FTokens[FTokens.Count - 2]) = 'END') and {do not localize}
          (FTokens[FTokens.Count - 1] = ';')) or {do not localize}
         ((InSpecial and
          (FTokens.Count = 5) and
          (AnsiUpperCase(FTokens[0]) = 'ALTER') and {do not localize}
          (AnsiUpperCase(FTokens[1]) = 'TRIGGER') and {do not localize}
          ((AnsiUpperCase(FTokens[3]) = 'ACTIVE') or {do not localize}
           (AnsiUpperCase(FTokens[3]) = 'INACTIVE')) and {do not localize}
          (FTokens[4] = ';')))) then {do not localize}
      begin
        if InSpecial then
        begin
          Result := Copy(Result, 1, Length(Result) - 1);
          InSpecial := false;
        end;
        Done := true;
        Result := Result + NextWord;
        Delete(FWork, 1, Length(NextWord) + Length(FTerminator));
        NextWord := Trim(AnsiUpperCase(NextWord));
        if NextWord > '' then
          FTokens.Add(AnsiUpperCase(NextWord));
        Exit;
      end;

      { Are we entering or exiting an inline comment? }
      if (Index < Length(FWork)) and ((not Indouble) or (not InQuote)) and
        (FWork[Index] = '/') and (FWork[Index + 1] = '*') then     {do not localize}
        InComment := true;
      if InComment and (Index <> 1) and
         (FWork[Index] = '/') and (FWork[Index - 1] = '*') then     {do not localize}
        InComment := false;

      if not InComment then
        { Handle case when the character is a single quote or a double quote }
        case FWork[Index] of
          QUOTE:
            if not InDouble then
            begin
              if InQuote then
              begin
                InQuote := false;
                SDone := true;
              end
              else
                InQuote := true;
            end;
          DBL_QUOTE:
            if not InQuote then
            begin
              if InDouble then
              begin
                Indouble := false;
                SDone := true;
              end
              else
                InDouble := true;
            end;
          ' ':                   {do not localize}
            if (not InDouble) and (not InQuote) then
              SDone := true;
        end;
      NextWord := NextWord + FWork[Index];
      Inc(Index);
    end;
    { copy over the remaining non character or spaces until the next word }
    while (Index <= Length(FWork)) and (FWork[Index] <= #32) do
    begin
      NextWord := NextWord + FWork[Index];
      Inc(Index);
    end;
    Result := Result + NextWord;
    Delete(FWork, 1, Length(NextWord));
    NextWord := Trim(NextWord);
    if NextWord > '' then
      FTokens.Add(NextWord);
    if (FTokens.Count = 2) and
       ((AnsiUpperCase(FTokens[0]) = 'CREATE') or {do not localize}
        (AnsiUpperCase(FTokens[0]) = 'ALTER')) and {do not localize}
      ((AnsiUpperCase(NextWord) = 'PROCEDURE') or {do not localize}
       (AnsiUpperCase(NextWord) = 'TRIGGER')) and  {do not localize}
       (FTerminator = ';') then {do not localize}
      InSpecial := true;
    if InSpecial and (AnsiUpperCase(NextWord) = 'END;') then {do not localize}
    begin
      FTokens[FTokens.Count - 1] := Copy(FTokens[FTokens.Count - 1], 1, 3);
      FTokens.Add(';'); {do not localize}
    end;
    if InSpecial and (FTokens.Count = 4) and
      (AnsiUpperCase(FTokens[0]) = 'ALTER') and {do not localize}
      (AnsiUpperCase(FTokens[1]) = 'TRIGGER') and {do not localize}
      ((AnsiUpperCase(FTokens[3]) = 'ACTIVE;') or {do not localize}
       ((AnsiUpperCase(FTokens[3]) = 'INACTIVE;'))) then {do not localize}
    begin
      if AnsiUpperCase(NextWord) = 'ACTIVE;' then {do not localize}
        FTokens[FTokens.Count - 1] := Copy(FTokens[FTokens.Count - 1], 1, 6)
      else
        FTokens[FTokens.Count - 1] := Copy(FTokens[FTokens.Count - 1], 1, 8);
      FTokens.Add(';'); {do not localize}
    end;

  end;

begin
  InSpecial := false;
  FTokens.Clear;
  if Trim(FWork) = '' then
    AppendNextLine;
  if not InInput then
    LineIndex := ScriptIndex;
  try
    RemoveComment;
  except
    on E: Exception do
    begin
      DoOnError(E.Message, '');
      exit;
    end
  end;
  InQuote := false;
  InDouble := false;
  InComment := false;
  Done := false;
  Result := '';
  while not Done do
  begin
    { Check the work queue, if it is empty get the next line to process }
    if FWork = '' then
      if not AppendNextLine then
        exit;
    ScanToken;
  end;
end;

{ TIBScript }

constructor TIBScript.Create(AOwner: TComponent);
begin
  inherited;
  FSQLParser := TIBSQLParser.Create(self);
  FSQLParser.OnError := ParserError;
  FSQLParser.OnParse := ParserParse;
  Terminator := ';';                    {do not localize}
  FDDLTransaction := TIBTransaction.Create(self);
  FDDLQuery := TIBSQL.Create(self);
  FDDLQuery.ParamCheck := false;
  FAutoDDL := true;
  FStatsOn := true;
  FStats := TIBScriptStats.Create;
  FStats.Database := FDatabase;
  FSQLDialect := 3;
end;

destructor TIBScript.Destroy;
begin
  FStats.Free;
  inherited;
end;

procedure TIBScript.DoConnect(const SQLText: string);
var
  i: integer;
  Param: string;
begin
  if (not Assigned(Database)) or
     (Database.Owner <> self) then
    SetupNewConnection;
  if Database.Connected then
    Database.Connected := false;
  Database.SQLDialect := FSQLDialect;
  Database.Params.Clear;
  Database.DatabaseName := StripQuote(FSQLParser.CurrentTokens[1]);
  i := 2;
  while i < FSQLParser.CurrentTokens.Count - 1 do
  begin
    if AnsiCompareText(FSQLParser.CurrentTokens[i], 'USER') = 0 then   {do not localize}
      Param := 'user_name';                                            {do not localize}
    if AnsiCompareText(FSQLParser.CurrentTokens[i], 'PASSWORD') = 0 then  {do not localize}
      Param := 'password';                                              {do not localize}
    if AnsiCompareText(FSQLParser.CurrentTokens[i], 'ROLE') = 0 then   {do not localize}
      Param := 'user_role';                                            {do not localize}
    Database.Params.Add(Param + '=' + StripQuote(FSQLParser.CurrentTokens[i +
      1]));
    Inc(i, 2);
  end;
  if FCharSet > '' then
    Database.Params.Add('lc_ctype=' + FCharSet); {do not localize}
  Database.Connected := true;
end;

procedure TIBScript.DoCreate(const SQLText: string);
var
  i: Integer;
begin
  SetupNewConnection;
  FDatabase.DatabaseName := StripQuote(FSQLParser.CurrentTokens[2]);
  i := 3;
  while i < FSQLParser.CurrentTokens.Count - 1 do
  begin
    Database.Params.Add(FSQLParser.CurrentTokens[i] + ' ' +
      FSQLParser.CurrentTokens[i + 1]);
    Inc(i, 2);
  end;
  FDatabase.SQLDialect := FSQLDialect;
  FDatabase.CreateDatabase;
  if FStatsOn and Assigned(FDatabase) and FDatabase.Connected then
    FStats.Start;
end;

procedure TIBScript.DoDDL(const Text: string);
begin
  if AutoDDL then
    FDDLQuery.Transaction := FDDLTransaction
  else
    FDDLQuery.Transaction := FTransaction;
  if not FDDLQuery.Transaction.InTransaction then
    FDDLQuery.Transaction.StartTransaction;

  FDDLQuery.SQL.Text := Text;
  FDDLQuery.ExecQuery;
  if AutoDDL then
    FDDLTransaction.Commit;
end;

procedure TIBScript.DoDML(const Text: string);
var
  FPaused : Boolean;
begin
  FPaused := false;
  if Assigned(FDataSet) then
  begin
    if FDataSet.Active then
      FDataSet.Close;
    FDataSet.SelectSQL.Text := Text;
    FDataset.Prepare;
    if (FDataSet.Params.Count <> 0) and Assigned(FOnParamCheck) then
    begin
      FOnParamCheck(self, FPaused);
      if FPaused then
      begin
        FSQLParser.Paused := true;
        exit;
      end;
    end;
    if FDataset.SQLType = SQLSelect then
      FDataSet.Open
    else
      FDataset.ExecSQL;
  end
  else
  begin
    if FDMLQuery.Open then
      FDMLQuery.Close;
    FDMLQuery.SQL.Text := Text;
    if not FDMLQuery.Transaction.InTransaction then
      FDMLQuery.Transaction.StartTransaction;
    FDMLQuery.Prepare;
    if (FDMLQuery.Params.Count <> 0) and Assigned(FOnParamCheck) then
    begin
      FOnParamCheck(self, FPaused);
      if FPaused then
      begin
        FSQLParser.Paused := true;
        exit;
      end;
    end;
    FDMLQuery.ExecQuery;
  end;
end;

procedure TIBScript.DoReconnect;
begin
  if Assigned(FDatabase) then
  begin
    FDatabase.Connected := false;
    FDatabase.Connected := true;
  end;
end;

procedure TIBScript.DoSET(const Text: string);
begin
  if AnsiCompareText('AUTODDL', FSQLParser.CurrentTokens[1]) = 0 then    {do not localize}
    FAutoDDL := FSQLParser.CurrentTokens[2] = 'ON'                    {do not localize}
  else
    if AnsiCompareText('STATISTICS', FSQLParser.CurrentTokens[1]) = 0 then {do not localize}
      Statistics := FSQLParser.CurrentTokens[2] = 'ON'               {do not localize}
    else
      if (AnsiCompareText('SQL', FSQLParser.CurrentTokens[1]) = 0) and  {do not localize}
         (AnsiCompareText('DIALECT', FSQLParser.CurrentTokens[2]) = 0) then  {do not localize}
      begin
        FSQLDialect := StrToInt(FSQLParser.CurrentTokens[3]);
        if Assigned(Database) and
           (Database.SQLDialect <> FSQLDialect) then
        begin
          if Database.Connected then
          begin
            Database.Close;
            Database.SQLDialect := FSQLDialect;
            Database.Open;
          end
          else
            Database.SQLDialect := FSQLDialect;
        end;
      end
      else
      if (AnsiCompareText('NAMES', FSQLParser.CurrentTokens[1]) = 0) then  {do not localize}
        FCharSet := FSQLParser.CurrentTokens[2];
end;

procedure TIBScript.DropDatabase(const SQLText: string);
begin
  FDatabase.DropDatabase;
end;

procedure TIBScript.ExecuteScript;
begin
  FContinue := true;
  FExecuting := true;
  FCharSet := '';
  if not Assigned(FDataset) then
    FDMLQuery := TIBSQL.Create(FDatabase);
  try
    FStats.Clear;
    if FStatsOn and Assigned(FDatabase) and FDatabase.Connected then
      FStats.Start;
    FSQLParser.Parse;
    if FStatsOn then
      FStats.Stop;
  finally
    FExecuting := false;
    if Assigned(FDMLQuery) then
      FreeAndNil(FDMLQuery);
  end;
end;

function TIBScript.GetPaused: Boolean;
begin
  Result := FSQLParser.Paused;
end;

function TIBScript.GetScript: TStrings;
begin
  Result := FSQLParser.Script;
end;

function TIBScript.GetSQLParams: TIBXSQLDA;
begin
  if Assigned(FDataset) then
    Result := FDataset.Params
  else
    Result := FDMLQuery.Params;
end;

function TIBScript.GetTokens: TStrings;
begin
  Result := FSQLParser.CurrentTokens;
end;

procedure TIBScript.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FDataset then
      FDataset := nil
    else
      if AComponent = FDatabase then
        FDatabase := nil
      else
        if AComponent = FTransaction then
          FTransaction := nil;
  end;
end;

function TIBScript.ParamByName(Idx: String): TIBXSQLVAR;
begin
  if Assigned(FDataset) then
    Result := FDataset.ParamByName(Idx)
  else
    Result := FDMLQuery.ParamByName(Idx);
end;

procedure TIBScript.ParserError(Sender: TObject; Error,
  SQLText: string; LineIndex: Integer);
begin
  if Assigned(FOnError) then
    FOnError(Self, Error, SQLText, LineIndex);
  FValidate := false;
  FSQLParser.Paused := true;
end;

procedure TIBScript.ParserParse(Sender: TObject; AKind: TIBParseKind;
  SQLText: string);

  function GetSavepointName : String;
  begin
    Result := '';
    if ((FSQLParser.CurrentTokens.Count = 4) and
          (AnsiUpperCase(FSQLParser.CurrentTokens[1]) = 'TO') and   {do not localize}
          (AnsiUpperCase(FSQLParser.CurrentTokens[2]) = 'SAVEPOINT')) then  {do not localize}
      Result := FSQLParser.CurrentTokens[3];

    if ((FSQLParser.CurrentTokens.Count = 5) and {do not localize}
          (AnsiUpperCase(FSQLParser.CurrentTokens[2]) = 'TO') and  {do not localize}
          (AnsiUpperCase(FSQLParser.CurrentTokens[3]) = 'SAVEPOINT')) then  {do not localize}
      Result := FSQLParser.CurrentTokens[4];
  end;

begin
  try
    FCurrentStmt := AKind;
    if not FValidating then
      case AKind of
        stmtDrop : DropDatabase(SQLText);
        stmtDDL : DoDDL(SQLText);
        stmtDML: DoDML(SQLText);
        stmtSET: DoSET(SQLText);
        stmtCONNECT: DoConnect(SQLText);
        stmtCREATE: DoCreate(SQLText);
        stmtTERM: FTerminator := Trim(SQLText);
        stmtCOMMIT:
        begin
          if FTransaction.InTransaction then
            FTransaction.Commit;
          if Assigned(FDDLTransaction) and FDDLTransaction.InTransaction then
            FDDLTransaction.Commit;
        end;
        stmtROLLBACK:
        begin
          if FTransaction.InTransaction then
            FTransaction.Rollback;
          if Assigned(FDDLTransaction) and FDDLTransaction.InTransaction then
            FDDLTransaction.Rollback;
        end;
        stmtReconnect:
          DoReconnect;
        stmtRollbackSavepoint :
          FTransaction.RollbackSavepoint(GetSavePointName);
        stmtReleaseSavePoint :
          FTransaction.ReleaseSavepoint(FSQLParser.CurrentTokens[1]);
        stmtStartSavepoint :
          FTransaction.StartSavepoint(FSQLParser.CurrentTokens[1]);
      end;
    if Assigned(FOnParse) then
      FOnParse(self, AKind, SQLText);
  except
    on E: EIBError do
    begin
      FContinue := false;
      FValidate := false;
      FSQLParser.Paused := true;
      if Assigned(FOnExecuteError) then
        FOnExecuteError(Self, E.Message, SQLText, FSQLParser.CurrentLine,
          FContinue)
      else
        raise;
      if FContinue then
        FSQLParser.Paused := false;
    end;
  end;
end;

procedure TIBScript.SetDatabase(const Value: TIBDatabase);
begin
  if FDatabase <> Value then
  begin
    FDatabase := Value;
    FDDLQuery.Database := Value;
    FDDLTransaction.DefaultDatabase := Value;
    FStats.Database := Value;
    if Assigned(FDMLQuery) then
      FDMLQuery.Database := Value;
  end;
end;

procedure TIBScript.SetPaused(const Value: Boolean);
begin
  if FSQLParser.Paused and (FCurrentStmt = stmtDML) then
    if Assigned(FDataSet) then
    begin
      if FDataset.SQLType = SQLSelect then
        FDataSet.Open
      else
        FDataset.ExecSQL;
    end
    else
    begin
      FDMLQuery.ExecQuery;
    end;
  FSQLParser.Paused := Value;
end;

procedure TIBScript.SetScript(const Value: TStrings);
begin
  FSQLParser.Script.Assign(Value);
end;

procedure TIBScript.SetStatsOn(const Value: boolean);
begin
  if FStatsOn <> Value then
  begin
    FStatsOn := Value;
    if FExecuting then
    begin
      if FStatsOn then
        FStats.Start
      else
        FStats.Stop;
    end;
  end;
end;

procedure TIBScript.SetTerminator(const Value: string);
begin
  if FTerminator <> Value then
  begin
    FTerminator := Value;
    FSQLParser.Terminator := Value;
  end;
end;

procedure TIBScript.SetTransaction(const Value: TIBTransaction);
begin
  FTransaction := Value;
  if Assigned(FDMLQuery) then
    FDMLQuery.Transaction := Value;
end;

procedure TIBScript.SetupNewConnection;
begin
  if Assigned(FDatabase) then
  begin
    FDDLTransaction.RemoveDatabase(FDDLTransaction.FindDatabase(FDatabase));
    if FDatabase.Owner = self then
      FDatabase.Free;
  end;
  Database := TIBDatabase.Create(self);
  Database.LoginPrompt := false;
  if Assigned(FTransaction) and (FTransaction.Owner = self) then
    FTransaction.Free;
  FTransaction := TIBTransaction.Create(self);
  FDatabase.DefaultTransaction := FTransaction;
  FTransaction.DefaultDatabase := FDatabase;
  FDDLTransaction.DefaultDatabase := FDatabase;
  FDDLQuery.Database := FDatabase;
  if Assigned(FDataset) then
  begin
    FDataset.Database := FDatabase;
    FDataset.Transaction := FTransaction;
  end;
end;

function TIBScript.StripQuote(const Text: string): string;
begin
  Result := Text;
  if Result[1] in [Quote, DBL_QUOTE] then
  begin
    Delete(Result, 1, 1);
    Delete(Result, Length(Result), 1);
  end;
end;

function TIBScript.ValidateScript: Boolean;
begin
  FValidating := true;
  FValidate := true;
  FSQLParser.Parse;
  Result := FValidate;
  FValidating := false;
end;

{ TIBScriptStats }

function TIBScriptStats.AddStringValues(list: TStrings): int64;
var
  i : integer;
  index : integer;
begin
  try
    Result := 0;
    for i := 0 to list.count-1 do
    begin
      index := Pos('=', list.strings[i]);   {do not localize}
      if index > 0 then
        Result := Result + StrToInt(Copy(list.strings[i], index + 1, 255));
    end;
  except
    Result := 0;
  end;
end;

procedure TIBScriptStats.Clear;
begin
  FBuffers := 0;
  FReads := 0;
  FWrites := 0;
  FSeqReads := 0;
  FFetches := 0;
  FReadIdx := 0;
  FDeltaMem := 0;
end;

constructor TIBScriptStats.Create;
begin
  FInfoStats := TIBDatabaseInfo.Create(nil);
end;

destructor TIBScriptStats.Destroy;
begin
  FInfoStats.Destroy;
  inherited;
end;

procedure TIBScriptStats.SetDatabase(const Value: TIBDatabase);
begin
  FDatabase := Value;
  FInfoStats.Database := Value;
end;

procedure TIBScriptStats.Start;
begin
  FStartBuffers := FInfoStats.NumBuffers;
  FStartReads := FInfoStats.Reads;
  FStartWrites := FInfoStats.Writes;
  FStartSeqReads := AddStringValues(FInfoStats.ReadSeqCount);
  FStartFetches := FInfoStats.Fetches;
  FStartReadIdx := AddStringValues(FInfoStats.ReadIdxCount);
  FStartingMem := FInfoStats.CurrentMemory;
end;

procedure TIBScriptStats.Stop;
begin
  FBuffers := FInfoStats.NumBuffers - FStartBuffers + FBuffers;
  FReads := FInfoStats.Reads - FStartReads + FReads;
  FWrites := FInfoStats.Writes - FStartWrites + FWrites;
  FSeqReads := AddStringValues(FInfoStats.ReadSeqCount) - FStartSeqReads + FSeqReads;
  FReadIdx := AddStringValues(FInfoStats.ReadIdxCount) - FStartReadIdx + FReadIdx;
  FFetches := FInfoStats.Fetches - FStartFetches + FFetches;
  FDeltaMem := FInfoStats.CurrentMemory - FStartingMem + FDeltaMem;
end;

end.
