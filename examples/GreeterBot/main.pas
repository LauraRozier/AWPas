unit main;

interface

uses
  SysUtils, AWPas;

{$I GreeterBot.inc}

type
  TMainClass = class(TObject)
    private
      fHost: string;
      fPort: Integer;
      fInstance: PPointer;
      procedure handle_avatar_add;
    protected
      // None
    public
      constructor Create(aHost: PAnsiChar; aPort: Integer; aInstance: PPointer);
      destructor Destroy;
      procedure RunBot;
  end;

implementation

constructor TMainClass.Create(aHost: PAnsiChar; aPort: Integer; aInstance: PPointer);
begin
  fHost     := aHost;
  fPort     := aPort;
  fInstance := aInstance;
end;

destructor TMainClass.Destroy;
begin
  // Cleanup
  aw_destroy;
  aw_term;
  WriteLn('Done cleaning up');
end;

procedure TMainClass.handle_avatar_add;
var
  _message: AnsiString;
begin
  _message := 'Hello ' + aw_string(AW_AVATAR_NAME);
  aw_say(_message);
  // log the event to the console
  WriteLn('User ' + aw_string(AW_AVATAR_NAME) + ' joined');
end;

procedure TMainClass.RunBot;
var
  errCode: Integer;
begin
  // Initialize the API
  errCode := aw_init(AW_BUILD);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to initialize API');

  writeln('API initialized' + sLineBreak);
  // Install the handler for the avatar_add event
  errCode := aw_event_set(AW_EVENT_AVATAR_ADD, handle_avatar_add);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to create event handler');

  writeln('Event handler set' + sLineBreak);
  // Create the bot instance
  errCode := aw_create(fHost, fPort, fInstance);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to create bot instance');

  writeln('Bot instance initialized' + sLineBreak);
  // log bot into the universe
	aw_string_set(AW_LOGIN_NAME, LOGIN_NAME);
	aw_int_set(AW_LOGIN_OWNER, CITIZEN_NUMBER);
	aw_string_set(AW_LOGIN_PRIVILEGE_PASSWORD, LOGIN_PRIVILEGE_PASSWORD);
	aw_string_set(AW_LOGIN_APPLICATION, LOGIN_APPLICATION_NAME);

  errCode := aw_login;
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

	if (errCode <> 0) then
    raise Exception.Create('Unable to login');

	writeln('Bot Logged in' + sLineBreak);
	// log bot into the world
  errCode := aw_enter(WORLD_NAME);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

	if (errCode <> 0) then
    raise Exception.Create('Unable to enter world');

	writeln('Bot entered World' + sLineBreak + sLineBreak +
          aw_string(AW_WORLD_WELCOME_MESSAGE) + sLineBreak);
	// announce our position in the world
	aw_int_set(AW_MY_X, BOT_X_POS);
	aw_int_set(AW_MY_Y, 1000);      // Height
	aw_int_set(AW_MY_Z, BOT_Z_POS);
	aw_int_set(AW_MY_YAW, BOT_YAW);
  errCode := aw_state_change;
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

	if (errCode <> 0) then
    raise Exception.Create('Unable to change state');

	writeln('Bot state set' + sLineBreak);

  while True do
  begin
    aw_wait(1);
    sleep(1);
  end;
end;

end.
