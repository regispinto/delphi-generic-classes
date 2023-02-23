unit uFunctions;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.StrUtils,
  Data.DB, Vcl.Grids, FireDAC.Comp.Client, IniFiles, WinSvc;

  function ChangePointToComma(Value: string): string;
  function SaveLog(Log: string; Separator: Boolean=False): string;
  function ReturnID(Connection: TFDConnection; Table, Field: string; LastPlusOne: Boolean=False): Integer;
  function IniParamsNOTExists(FileName: string='Config.ini'): Boolean;
  function GetFileFromUrl(Url: String): String;
  function LoadIni(Key1, Key2, DefaultValue: string; FileName: string='config.ini'): String;

  procedure SaveIni(Key1, Key2, aTexto: string; FileName: string='config.ini');

  procedure CreateIniParams(DriverName: string);
  procedure CreatePath(var Path: string);
  procedure CreateFile(FileName: string='config.ini');

Const
  CR = #13;

implementation

procedure SaveIni(Key1, Key2, aTexto: string; FileName: string='config.ini');
var
  ArqIni: TIniFile;

begin
  ArqIni := TIniFile.Create(System.SysUtils.GetCurrentDir + '\' + FileName);

  try
    ArqIni.WriteString(Key1, Key2, aTexto);
  finally
    ArqIni.Free;
  end;
end;

function LoadIni(Key1, Key2, DefaultValue: string; FileName: string='config.ini'): String;
var
  ArqIni: TIniFile;
  FilePath: String;

begin
  FilePath := ExtractFilePath(ParamStr(0)) + FileName;

  Result := DefaultValue;

  try
    ArqIni := TIniFile.Create(FilePath);

    if FileExists(FilePath) then
      Result := ArqIni.ReadString(Key1, Key2, DefaultValue)

  finally
    FreeAndNil(ArqIni)
  end;
end;

function IniParamsNOTExists(FileName: string='Config.ini'): Boolean;
begin
  SaveLog('uFunctions/IniParamsNOTExists -> Validando se o ' + FileName + ' existe');

  if (FileExists(FileName)) then
  begin
    SaveLog('uFunctions/IniParamsNOTExists -> Arquivo de parâmetros ' + FileName + ' já existe' );
    Result := False
  end
  else
    begin
      SaveLog('uFunctions/IniParamsNOTExists -> Arquivo de parâmetros ' + FileName + ' não existe, deve criar' );
      Result := True;
    end;
end;

procedure CreateIniParams(DriverName: string);
begin
  SaveLog('uFunctions/CreateIniParams -> Gravando parâmetros de acesso ao banco de dados ' + DriverName);

  case AnsiIndexStr(UpperCase(DriverName), ['SQLITE', 'MYSQL', 'FB', 'PG']) of
    0:  begin
        end;

    1:  begin
          SaveIni('BANCO', 'port', '3306');
          SaveIni('BANCO', 'database', 'db_dados');
          SaveIni('BANCO', 'server', '127.0.0.1');
          SaveIni('BANCO', 'user_name', 'root');
          SaveIni('BANCO', 'password', 'root');
        end;

    2:  begin
          SaveIni('BANCO', 'port', '3350');
          SaveIni('BANCO', 'database', 'db_dados.fdb');
          SaveIni('BANCO', 'server', '127.0.0.1');
          SaveIni('BANCO', 'user_name', 'SYSDBA');
          SaveIni('BANCO', 'password', 'masterkey');
        end;

    3:  begin
          SaveIni('BANCO', 'port', '5432');
          SaveIni('BANCO', 'database', 'db_pessoas');
          SaveIni('BANCO', 'server', '127.0.0.1');
          SaveIni('BANCO', 'user_name', 'postgres');
          SaveIni('BANCO', 'password', '12345678');
          SaveIni('BANCO', 'obdc', ExtractFilePath(ParamStr(0)) + 'lib');
        end;
  end;
end;

function ChangePointToComma(Value: string): string;
begin
  Result := Trim(StringReplace(Value, ',', '.', [rfReplaceall]));
end;

function ReturnID(Connection: TFDConnection; Table, Field: string;
  LastPlusOne: Boolean=False): Integer;
var
  Qry: TFDQuery;

begin
  Try
    Qry := TFDQuery.Create(nil);

    Qry.Connection := Connection;
    Qry.Close;
    Qry.SQL.Clear;
    Qry.SQL.Add('SELECT MAX(' + Field + ') as CurrentID FROM ' + Table);
    SaveLog('uFunctions.ReturnID: ' + CR + Qry.SQL.Text);
    Qry.Open;

    if Qry.FieldByName('CURRENTID').IsNull then
      Result := 1
    else
      if LastPlusOne then
        Result := Qry.FieldByName('CURRENTID').AsInteger + 1
      else
        Result := Qry.FieldByName('CURRENTID').AsInteger;

    SaveLog('uFunctions.ReturnID - ID Gerado: ' + IntToStr(Result));
  finally
    FreeAndNil(Qry);
  end;
end;

function SaveLog(Log: string; Separator: Boolean=False): string;
Var
  NameLog, TextLog: String;
  FileLog: TextFile;

begin
  NameLog := ExtractFilePath(Application.ExeName) + FormatDateTime('yyyymmdd', now) + '.log';

  AssignFile(FileLog, NameLog);

  if FileExists(NameLog) then
    Append(FileLog)
  else
    ReWrite(FileLog);

  if Not FileExists(ExtractFilePath(Application.ExeName) + NameLog) then
    FileCreate(ExtractFilePath(Application.ExeName) + NameLog);

  try
    TextLog := ('[' + FormatDateTime('hh:nn:ss', now) + '] - ' + Log);

    if Separator then
      TextLog := TextLog + CR + Dupestring('-', 40);

    WriteLn(FileLog, TextLog);
  finally
    CloseFile(FileLog);
  end;
end;

procedure CreatePath(var Path: String);
var
  LPath: String;

begin
  LPath := System.SysUtils.GetCurrentDir;
  Path := LPath + Path;
  ForceDirectories(Path);
end;

procedure CreateFile(FileName: String='config.ini');
var
  LFile: TextFile;
  LTexto: string;

begin
  try
    try
      AssignFile(LFile, FileName);
      Rewrite(LFile);
      SaveLog('uFunctions/CreateFile -> Arquivo ' + FileName + ' criado com sucesso');
    except
      on E:Exception do
        begin
          LTexto := 'Ocorreu um erro ao criar o arquivo ' + FileName + CR +
            e.ToString + CR + e.ClassName;
          raise Exception.Create(LTexto);
          SaveLog('uFunctions/CreateFile -> ' + LTexto);
        end;
    end;
  finally
    CloseFile(LFile)
  end;
end;

function GetFileFromUrl(Url: String): String;
var
  pos: ShortInt;

begin
  pos := LastDelimiter('/', Url);

  Result := Copy(url, pos + 1, MaxInt);
end;

end.
