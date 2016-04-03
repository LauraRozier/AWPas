program DJBot;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  Windows,
  AWPas in '..\..\AWPas.pas',
  main in 'main.pas';

{$I DJBot.inc}

var
  mainClass: TMainClass;

function ConsoleEventProc(dwCtrlType: DWORD): BOOL; stdcall;
begin
  // Avoid default termination
  if dwCtrlType in [CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT,
                    CTRL_LOGOFF_EVENT, CTRL_SHUTDOWN_EVENT] then
  begin
    FreeAndNil(mainClass);
    WriteLn(sLineBreak + 'GC done!' + sLineBreak + 'Closing down the bot.');
    result   := True;
    ExitCode := 0;
    sleep(1000);
    halt;
  end else
    result := False;
end;

begin
  try
    SetConsoleCtrlHandler(@ConsoleEventProc, True);
    { initialize Active Worlds API }
    mainClass := TMainClass.Create(SERVER_ADDRESS, SERVER_PORT, SERVER_INSTANCE);
    { Start the bot }
    mainClass.RunBot;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
