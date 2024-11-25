unit fMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SSHTunnel, StdCtrls, ExtCtrls, Menus, Registry;

type
  Tf_Main = class(TForm)
    bStart: TButton;
    bStop: TButton;
    TrayIcon: TTrayIcon;
    PopupMenu: TPopupMenu;
    Timer: TTimer;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    EditLogin: TEdit;
    EditPassword: TEdit;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    EditAdres: TEdit;
    EditPort: TEdit;
    GroupBox3: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    EditLocalPort: TEdit;
    EditRemotePort: TEdit;
    Open: TMenuItem;
    Exit: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TrayIconClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure bStopClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    private
      { Private declarations }
      Tunnel: TSSHTunnel;
    public
      { Public declarations }
  end;

var
  f_Main: Tf_Main;

implementation

{$R *.dfm}

procedure AddToStartup;
var
  Reg: TRegistry;
  AppName, AppPath: string;
begin
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True) then
      begin
        AppName := 'StunnelManager'; // Имя приложения
        AppPath := ParamStr(0); // Полный путь к исполняемому файлу
        Reg.WriteString(AppName, AppPath); // Добавляем запись
      end;
  finally
    Reg.Free;
  end;
end;

procedure RemoveFromStartup;
var
  Reg: TRegistry;
  AppName: string;
begin
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False) then
      begin
        AppName := 'StunnelManager';
        if Reg.ValueExists(AppName) then
          Reg.DeleteValue(AppName);
      end;
  finally
    Reg.Free;
  end;
end;

procedure Tf_Main.bStartClick(Sender: TObject);
begin
  try
    if not Assigned(Tunnel) then
      Tunnel := TSSHTunnel.Create(EditAdres.Text, EditLogin.Text,
        EditPassword.Text, StrToInt(EditPort.Text), StrToInt(EditLocalPort.Text),
        StrToInt(EditRemotePort.Text));

    if Tunnel.StartTunnel then
    begin
      ShowMessage('Туннель успешно запущен.');

      // Скрываем главное окно
      Self.Hide;

      // Отображаем иконку в трее
      TrayIcon.Visible := True;
      TrayIcon.ShowBalloonHint; // По желанию, отображаем подсказку
    end
    else
      ShowMessage('Ошибка запуска туннеля.');
  except
    on E: Exception do
      ShowMessage('Ошибка: ' + E.Message);
  end;

  Timer.Enabled := True; // Запускаем таймер для проверки состояния туннеля
end;


procedure Tf_Main.bStopClick(Sender: TObject);
begin
  if Assigned(Tunnel) then
    begin
      Tunnel.StopTunnel;
      FreeAndNil(Tunnel);
      ShowMessage('Туннель остановлен.');
    end
  else
    ShowMessage('Туннель не запущен.');
end;

procedure Tf_Main.ExitClick(Sender: TObject);
begin
  if Assigned(Tunnel) then
    Tunnel.StopTunnel;
  Application.Terminate;
end;

procedure Tf_Main.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
  TrayIcon.Visible := True; // Показываем значок в трее
  TrayIcon.ShowBalloonHint; // Отображаем подсказку (по желанию)
end;

procedure Tf_Main.OpenClick(Sender: TObject);
begin
  Self.Show;
  Application.Restore;
  TrayIcon.Visible := False;
end;

procedure Tf_Main.TimerTimer(Sender: TObject);
begin
  if Assigned(Tunnel) and (Tunnel.FForwardingChannel <> nil) then
    TrayIcon.Hint := 'Туннель активен'
  else
    TrayIcon.Hint := 'Туннель остановлен';
end;

procedure Tf_Main.TrayIconClick(Sender: TObject);
begin
  Self.Show;
  Application.Restore;
  TrayIcon.Visible := False; // Скрываем значок в трее
end;

end.
