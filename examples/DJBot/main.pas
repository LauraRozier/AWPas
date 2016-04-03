unit main;

interface

uses
  SysUtils, AWPas;

{$I DJBot.inc}

const
  MIDI_FILES: array[0..9] of string = ('class1.mid', 'class2.mid', 'class3.mid', 'class4.mid', 'class5.mid',
                                       'class6.mid', 'class7.mid', 'class8.mid', 'class9.mid', 'class10.mid');

threadvar
  fCell_x, fCell_z: Integer;
  fSequence: TQueryArray;
  fSpeaker_x, fSpeaker_y, fSpeaker_z: Integer;
  fSpeaker_yaw: Integer;
  fSpeaker_number: Integer;
  fCurrent_midi: Integer;

type
  TMainClass = class(TObject)
    private
      fHost: string;
      fPort: Integer;
      fInstance: PPointer;
      procedure handle_cell_begin;
      procedure handle_cell_object;
      procedure handle_query(rc: Integer);
      procedure change_midi;
    protected
      // None
    public
      constructor Create(aHost: PAnsiChar; aPort: Integer; aInstance: PPointer);
      destructor Destroy;
      procedure RunBot;
  end;

implementation

constructor TMainClass.Create(aHost: PAnsiChar; aPort: Integer; aInstance: PPointer);
var
  errCode: Integer;
begin
  fHost     := aHost;
  fPort     := aPort;
  fInstance := aInstance;

  // Initialize the API
  errCode := aw_init(AW_BUILD);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to initialize API');

  writeln('API initialized' + sLineBreak);

  // install cell update event handlers
  errCode := aw_event_set(AW_EVENT_CELL_BEGIN, handle_cell_begin);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to create event handler');

  errCode := aw_event_set(AW_EVENT_CELL_OBJECT, handle_cell_object);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to create event handler');

  // install query callback
  errCode := aw_callback_set(AW_CALLBACK_QUERY, handle_query);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to create event handler');

  writeln('Event handlers and callbacks set' + sLineBreak);
  // Create the bot instance
  errCode := aw_create(fHost, fPort, fInstance);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

  if (errCode <> 0) then
    raise Exception.Create('Unable to create bot instance');

  writeln('Bot instance initialized' + sLineBreak);
end;

destructor TMainClass.Destroy;
begin
  // Cleanup
  aw_destroy;
  aw_term;
  WriteLn('Done cleaning up');
end;

procedure TMainClass.RunBot;
var
  errCode: Integer;
  count: Integer;
begin
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
  {
    Note that we don't announce our presence by calling aw_state_change,
    so this bot will not physically appear in the world.
  }
	// Issue first property query for the ground zero area so that we can locate the SPEAKER_OBJECT
  writeLn('Looking for speaker...');
  errCode := aw_query (0, 0, fSequence);
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

	if (errCode <> 0) then
    raise Exception.Create('Unable to query data');

	writeLn('Data gathered' + sLineBreak);
  change_midi;

  while True do
  begin
    for count := 0 to FIVE_MINUTES do
    begin
      if count = FIVE_MINUTES then
      begin
        if (fSpeaker_number <> -1) then
          change_midi;

        aw_wait(FIVE_MINUTES);
      end;

      sleep(1);
    end;
  end;
end;


procedure TMainClass.change_midi;
var
  errCode: Integer;
  action: AnsiString;
begin
  aw_int_set(AW_OBJECT_OLD_NUMBER, fSpeaker_number);
  aw_int_set(AW_OBJECT_OLD_X, fSpeaker_x);
  aw_int_set(AW_OBJECT_OLD_Z, fSpeaker_z);
  aw_int_set(AW_OBJECT_X, fSpeaker_x);
  aw_int_set(AW_OBJECT_Y, fSpeaker_y);
  aw_int_set(AW_OBJECT_Z, fSpeaker_z);
  aw_int_set(AW_OBJECT_YAW, fSpeaker_yaw);
  aw_int_set(AW_OBJECT_TILT, 0);
  aw_int_set(AW_OBJECT_ROLL, 0);
  aw_int_set(AW_OBJECT_OWNER, CITIZEN_NUMBER);
  aw_string_set(AW_OBJECT_MODEL, SPEAKER_OBJECT);
  aw_string_set(AW_OBJECT_DESCRIPTION, 'Pascal API example MIDI Speaker');

  if fCurrent_midi > Length(MIDI_FILES) - 1 then
    fCurrent_midi := 0;

  action := 'Create sound ' + MIDI_FILES[fCurrent_midi];
  aw_string_set(AW_OBJECT_ACTION, action);
  errCode := aw_object_change;
  writeLn('Status code: '                  + IntToStr(errCode)        + sLineBreak +
          'VERBOSE: Status message: '      + aw_GetErrorText(errCode) + sLineBreak +
          'VERBOSE: Full status message: ' + aw_GetFullErrorText(errCode));

	if (errCode <> 0) then
    raise Exception.Create('Unable to change speaker');

  writeLn('Speaker changed.');
  fSpeaker_number := aw_int(AW_OBJECT_NUMBER);
end;

procedure TMainClass.handle_cell_begin;
var
  sector_x, sector_z: Integer;
  cellTmp_x, cellTmp_Y: Integer;
begin
  {
    This is called to indicate we are receiving the contents of a new cell.
    All we need to do here is update the sequence number array for the next call to aw_query ().
  }
  cellTmp_x := aw_int(AW_CELL_X);
  cellTmp_Y := aw_int(AW_CELL_Z);
  fCell_x := cellTmp_x;
  fCell_z := cellTmp_Y;
  sector_x := aw_sector_from_cell(cellTmp_x);
  sector_z := aw_sector_from_cell(cellTmp_Y);

  // Sanity check: make sure sector coordinates are within range
  if (sector_x < -1) or (sector_x > 1) or (sector_z < -1) or (sector_z > 1) then
    exit;

  fSequence[sector_z + 1][sector_x + 1] := aw_int(AW_CELL_SEQUENCE);
end;

procedure TMainClass.handle_cell_object;
begin
  {
    This is called once for each object in each cell that we are querying.
    We check to see if the object is the SPEAKER_OBJECT we are looking for,
    by checking the name of the object and the cell it is located in.
  }
  if (fCell_x = 1) and (fCell_z = 1) and (CompareStr(aw_string(AW_OBJECT_MODEL), SPEAKER_OBJECT) = 0) then
  begin
	  fSpeaker_x      := aw_int(AW_OBJECT_X);
    fSpeaker_y      := aw_int(AW_OBJECT_Y);
    fSpeaker_z      := aw_int(AW_OBJECT_Z);
    fSpeaker_yaw    := aw_int(AW_OBJECT_YAW);
    fSpeaker_number := aw_int(AW_OBJECT_NUMBER);
    writeLn('Speaker located!');
    change_midi;
  end;
end;

procedure TMainClass.handle_query(rc: Integer);
begin
  {
    This is called when the server has stopped sending property data.
    If we haven't found the speaker yet, then we check if the query is complete,
    and if not, issue a new query with the updated sequence numbers to continue the update.
  }
  if (fSpeaker_number <> -1) then
    if aw_bool(AW_QUERY_COMPLETE) then
      aw_query(0, 0, fSequence)
    else
      // The query is complete but we didn't find the speaker! :(
      writeLn('Couldn''t find speaker object.');
end;

end.

