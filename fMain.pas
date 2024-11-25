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
        AppName := 'StunnelManager'; // ��� ����������
        AppPath := ParamStr(0); // ������ ���� � ������������ �����
        Reg.WriteString(AppName, AppPath); // ��������� ������
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
      ShowMessage('������� ������� �������.');

      // �������� ������� ����
      Self.Hide;

      // ���������� ������ � ����
      TrayIcon.Visible := True;
      TrayIcon.ShowBalloonHint; // �� �������, ���������� ���������
    end
    else
      ShowMessage('������ ������� �������.');
  except
    on E: Exception do
      ShowMessage('������: ' + E.Message);
  end;

  Timer.Enabled := True; // ��������� ������ ��� �������� ��������� �������
end;


procedure Tf_Main.bStopClick(Sender: TObject);
begin
  if Assigned(Tunnel) then
    begin
      Tunnel.StopTunnel;
      FreeAndNil(Tunnel);
      ShowMessage('������� ����������.');
    end
  else
    ShowMessage('������� �� �������.');
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
  TrayIcon.Visible := True; // ���������� ������ � ����
  TrayIcon.ShowBalloonHint; // ���������� ��������� (�� �������)
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
    TrayIcon.Hint := '������� �������'
  else
    TrayIcon.Hint := '������� ����������';
end;

procedure Tf_Main.TrayIconClick(Sender: TObject);
begin
  Self.Show;
  Application.Restore;
  TrayIcon.Visible := False; // �������� ������ � ����
end;

end.
