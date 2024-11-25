unit SSHTunnel;

interface

uses
  SysUtils, Windows, Classes, WinSock;

const
  LIBSSH2_CALLBACK_IGNORE = 0;
  LIBSSH2_CALLBACK_DEBUG = 1;
  LIBSSH2_CALLBACK_DISCONNECT = 2;
  LIBSSH2_CALLBACK_MACERROR = 3;
  LIBSSH2_CALLBACK_X11 = 4;

  LIBSSH2_METHOD_KEX = 0;
  LIBSSH2_METHOD_HOSTKEY = 1;
  LIBSSH2_METHOD_CRYPT_CS = 2;
  LIBSSH2_METHOD_CRYPT_SC = 3;
  LIBSSH2_METHOD_MAC_CS = 4;
  LIBSSH2_METHOD_MAC_SC = 5;
  LIBSSH2_METHOD_COMP_CS = 6;
  LIBSSH2_METHOD_COMP_SC = 7;
  LIBSSH2_METHOD_LANG_CS = 8;
  LIBSSH2_METHOD_LANG_SC = 9;
  LIBSSH2_ERROR_SFTP_PROTOCOL = -31;
  LIBSSH2_FXF_WRITE = $00000002;
  LIBSSH2_FXF_CREAT = $00000008;
  LIBSSH2_FXF_READ = $00000001;
  LIBSSH2_FXF_APPEND = $00000004;
  LIBSSH2_FXF_TRUNC = $00000010;
  LIBSSH2_FXF_EXCL = $00000020;
  LIBSSH2_CHANNEL_WINDOW_DEFAULT = 65536;
  LIBSSH2_CHANNEL_PACKET_DEFAULT = 32768;

type
  LIBSSH2_PASSWD_CHANGEREQ_FUNC = procedure
    (session: Pointer; message: PAnsiChar; const len: Integer); cdecl;

  TSSHTunnel = class
    private
      FSession: Pointer;
      FSocket: TSocket;
      FHost: string;
      FUsername: string;
      FPassword: string;
      FPort: Integer;
      FLocalPort: Integer;
      FRemotePort: Integer;
      FLibSSH2: THandle;

      procedure LoadLibSSH2;
      procedure CheckError(ResultCode: Integer; const ErrorMessage: string);
      function CreateSocket: TSocket;
      function SetupPortForwarding: Pointer;
      function IsValidIP(const AHost: string): Boolean;
    public
      FForwardingChannel: Pointer;
      constructor Create(const Host, Username, Password: string; const Port,
        LocalPort: Integer; RemotePort: Integer);
      destructor Destroy; override;
      function ConnectServer: Boolean;
      function StartTunnel: Boolean;
      function StopTunnel: Boolean;
  end;

implementation

{ TSshTunnel }

type
  libssh2_init_func = function(flags: Integer): Integer; cdecl;
  libssh2_exit_func = procedure; cdecl;
  libssh2_session_init_ex_func = function(v1, v2, v3, v4: Pointer): Pointer;
    cdecl;
  libssh2_session_free_func = procedure(session: Pointer); cdecl;
  libssh2_session_handshake_func = function(session: Pointer; sock: TSocket)
    : Integer; cdecl;
  libssh2_userauth_password_ex_func = function(session: Pointer;
    Username: PAnsiChar; username_len: Integer; Password: PAnsiChar;
    password_len: Integer; passwd_change_cb: LIBSSH2_PASSWD_CHANGEREQ_FUNC)
    : Integer; cdecl;
  libssh2_session_method_pref_func = function(session: Pointer;
    method_type: Integer; const prefs: PAnsiChar): Integer; cdecl;
  libssh2_channel_direct_tcpip_ex_func = function
    (session: Pointer; Host: PAnsiChar; Port: Integer; shost: PAnsiChar;
    sport: Integer): Pointer; cdecl;
  libssh2_channel_close_func = function(channel: Pointer): Integer; cdecl;
  libssh2_channel_free_func = function(channel: Pointer): Integer; cdecl;
  libssh2_session_last_error_func = function
    (session: Pointer; var errmsg: PAnsiChar; var errmsg_len: Integer;
    want_buf: Integer): Integer; cdecl;
  libssh2_channel_open_ex_func = function(session: Pointer;
    const channel_type: PAnsiChar; channel_type_len: Integer;
    window_size: Integer; packet_size: Integer; const message: PAnsiChar;
    message_len: Integer): Pointer; cdecl;

var
  libssh2_init: libssh2_init_func;
  libssh2_exit: libssh2_exit_func;
  libssh2_session_init_ex: libssh2_session_init_ex_func;
  libssh2_session_free: libssh2_session_free_func;
  libssh2_session_handshake: libssh2_session_handshake_func;
  libssh2_userauth_password_ex: libssh2_userauth_password_ex_func;
  libssh2_session_method_pref: libssh2_session_method_pref_func;
  libssh2_channel_direct_tcpip_ex: libssh2_channel_direct_tcpip_ex_func;
  libssh2_channel_close: libssh2_channel_close_func;
  libssh2_channel_free: libssh2_channel_free_func;
  libssh2_session_last_error: libssh2_session_last_error_func;
  libssh2_channel_open_ex: libssh2_channel_open_ex_func;

constructor TSSHTunnel.Create(const Host, Username, Password: string;
  const Port, LocalPort: Integer; RemotePort: Integer);
begin
  FHost := Host;
  FUsername := Username;
  FPassword := Password;
  FPort := Port;
  FLocalPort := LocalPort;
  FRemotePort := RemotePort;

  FLibSSH2 := 0;
  FSession := nil;
  FSocket := INVALID_SOCKET;
  FForwardingChannel := nil;

  LoadLibSSH2;
end;

destructor TSSHTunnel.Destroy;
begin
  StopTunnel;

  if FSession <> nil then
    libssh2_session_free(FSession);

  if FSocket <> INVALID_SOCKET then
    closesocket(FSocket);

  if FLibSSH2 <> 0 then
    begin
      libssh2_exit();
      FreeLibrary(FLibSSH2);
    end;

  inherited;
end;

function TSSHTunnel.IsValidIP(const AHost: string): Boolean;
var
  Parts: TStringList;
  I: Integer;
  PartValue: Integer;
begin
  Result := False;

  // Check if AHost is a valid IP (simple format check)
  if (Pos('.', AHost) > 0) then
    begin
      Parts := TStringList.Create;
      try
        // Split the string by "."
        Parts.Delimiter := '.';
        Parts.DelimitedText := AHost;

        if Parts.Count = 4 then
          begin
            Result := True;
            for I := 0 to Parts.Count - 1 do
              begin
                if not TryStrToInt(Parts[I], PartValue) or (PartValue < 0) or
                  (PartValue > 255) then
                  begin
                    Result := False;
                    Break;
                  end;
              end;
          end;
      finally
        Parts.Free;
      end;
    end;
end;

procedure TSSHTunnel.LoadLibSSH2;
begin
  FLibSSH2 := LoadLibrary('lib\Win32\libssh2.dll');
  if FLibSSH2 = 0 then
    raise Exception.Create('Unable to load libssh2.dll');

  @libssh2_init := GetProcAddress(FLibSSH2, 'libssh2_init');
  @libssh2_exit := GetProcAddress(FLibSSH2, 'libssh2_exit');
  @libssh2_session_init_ex := GetProcAddress
    (FLibSSH2, 'libssh2_session_init_ex');
  @libssh2_session_free := GetProcAddress(FLibSSH2, 'libssh2_session_free');
  @libssh2_session_handshake := GetProcAddress(FLibSSH2,
    'libssh2_session_handshake');
  @libssh2_userauth_password_ex := GetProcAddress(FLibSSH2,
    'libssh2_userauth_password_ex');
  @libssh2_session_method_pref := GetProcAddress(FLibSSH2,
    'libssh2_session_method_pref');
  @libssh2_channel_direct_tcpip_ex := GetProcAddress(FLibSSH2,
    'libssh2_channel_direct_tcpip_ex');
  @libssh2_channel_open_ex := GetProcAddress
    (FLibSSH2, 'libssh2_channel_open_ex');
  @libssh2_channel_close := GetProcAddress(FLibSSH2, 'libssh2_channel_close');
  @libssh2_channel_free := GetProcAddress(FLibSSH2, 'libssh2_channel_free');
  @libssh2_session_last_error := GetProcAddress(FLibSSH2,
    'libssh2_session_last_error');
  if not Assigned(libssh2_userauth_password_ex) then
    raise Exception.Create('libssh2_userauth_password_ex function not found');

  if not Assigned(libssh2_channel_open_ex) then
    raise Exception.Create('libssh2_channel_open_ex function not found');
end;

procedure TSSHTunnel.CheckError(ResultCode: Integer;
  const ErrorMessage: string);
begin
  if ResultCode < 0 then
    raise Exception.CreateFmt('%s. Error code: %d', [ErrorMessage, ResultCode]);
end;

function WSAStartup(wVersionRequired: Word; var WSData: TWSAData): Integer;
  stdcall; external 'ws2_32.dll' name 'WSAStartup';

function TSSHTunnel.CreateSocket: TSocket;
var
  Addr: TSockAddrIn;
  HostEnt: PHostEnt;
  ErrorCode: Integer;
  WSAData: TWSAData;
begin
  Result := INVALID_SOCKET;

  // Инициализация Winsock
  ErrorCode := WSAStartup($0202, WSAData); // Версия 2.2
  if ErrorCode <> 0 then
    begin
      raise Exception.CreateFmt('WSAStartup failed with error: %d',
        [ErrorCode]);
    end;

  // Проверяем, является ли FHost IP-адресом
  if IsValidIP(FHost) then
    begin
      // Если FHost - это IP, просто используем его напрямую
      Addr.sin_family := AF_INET;
      Addr.sin_port := htons(FPort);
      Addr.sin_addr.S_addr := inet_addr(PAnsiChar(AnsiString(FHost)));
      // Преобразуем IP в нужный формат
    end
  else
    begin
      // Если FHost - это доменное имя, используем gethostbyname
      HostEnt := gethostbyname(PAnsiChar(AnsiString(FHost)));
      if HostEnt = nil then
        begin
          ErrorCode := WSAGetLastError;
          raise Exception.CreateFmt('Failed to resolve host. WSAError: %d',
            [ErrorCode]);
        end;

      Addr.sin_family := AF_INET;
      Addr.sin_port := htons(FPort);
      Addr.sin_addr.S_addr := PInAddr(HostEnt^.h_addr_list^)^.S_addr;
    end;

  // Создаем сокет
  Result := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Result = INVALID_SOCKET then
    begin
      ErrorCode := WSAGetLastError;
      raise Exception.CreateFmt('Failed to create socket. WSAError: %d',
        [ErrorCode]);
    end;

  // Подключаемся
  if connect(Result, Addr, SizeOf(Addr)) <> 0 then
    begin
      ErrorCode := WSAGetLastError;
      closesocket(Result);
      raise Exception.CreateFmt
        ('Failed to connect to remote host. WSAError: %d', [ErrorCode]);
    end;
end;

function TSSHTunnel.ConnectServer: Boolean;
var
  ResultCode: Integer;
  Username, Password: AnsiString;
  ChangePasswdCallback: LIBSSH2_PASSWD_CHANGEREQ_FUNC;
begin
  Result := False;

  // Initialize libssh2
  ResultCode := libssh2_init(0);
  CheckError(ResultCode, 'libssh2 initialization failed');

  // Create the SSH session
  FSession := libssh2_session_init_ex(nil, nil, nil, nil);
  if FSession = nil then
    raise Exception.Create('libssh2 session initialization failed');

  // Create and connect the socket
  FSocket := CreateSocket;

  // Set preferred host key algorithm
  ResultCode := libssh2_session_method_pref(FSession, LIBSSH2_METHOD_HOSTKEY,
    PAnsiChar(AnsiString('ssh-rsa,ssh-dss')));
  CheckError(ResultCode, 'Failed to set preferred host key method');

  // Perform the handshake
  ResultCode := libssh2_session_handshake(FSession, FSocket);
  CheckError(ResultCode, 'SSH handshake failed');

  // Ensure the session is valid before proceeding
  if FSession = nil then
    raise Exception.Create('Session is invalid before authentication');

  // Ensure username and password are not empty
  Username := AnsiString(FUsername);
  Password := AnsiString(FPassword);

  if (Username = '') or (Password = '') then
    raise Exception.Create('Username or password is empty');

  // Set up the password change callback (pass nil for no change)
  ChangePasswdCallback := nil;

  // Authenticate using username and password with length arguments
  ResultCode := libssh2_userauth_password_ex
    (FSession, PAnsiChar(Username), Length(Username), PAnsiChar(Password),
    Length(Password), ChangePasswdCallback);
  CheckError(ResultCode, 'Authentication failed');

  Result := True;
end;

function TSSHTunnel.SetupPortForwarding: Pointer;
var
  errmsg: PAnsiChar;
  errmsg_len: Integer;
begin

  if FSession = nil then
    raise Exception.Create('Session is not initialized or invalid');

  Result := libssh2_channel_open_ex(FSession, 'direct-tcpip', Length
      ('direct-tcpip'), LIBSSH2_CHANNEL_WINDOW_DEFAULT,
    LIBSSH2_CHANNEL_PACKET_DEFAULT, nil, 0);

  CheckError(Integer(Result), 'Failed to channel open');

  Result := libssh2_channel_direct_tcpip_ex
    (FSession, PAnsiChar(AnsiString(FHost)), FRemotePort, PAnsiChar
      (AnsiString('127.0.0.1')), FLocalPort);

  CheckError(Integer(Result), 'Failed to setup port forwarding');
end;

function TSSHTunnel.StartTunnel: Boolean;
begin
  if not ConnectServer then
    Exit(False);

  FForwardingChannel := SetupPortForwarding;
  Result := FForwardingChannel <> nil;
end;

function TSSHTunnel.StopTunnel: Boolean;
begin
  if FForwardingChannel <> nil then
    begin
      libssh2_channel_close(FForwardingChannel);
      libssh2_channel_free(FForwardingChannel);
      FForwardingChannel := nil;
    end;

  if FSocket <> INVALID_SOCKET then
    begin
      closesocket(FSocket);
      FSocket := INVALID_SOCKET;
    end;

  Result := True;
end;

end.
