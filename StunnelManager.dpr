program StunnelManager;

uses
  Forms,
  fMain in 'fMain.pas' {f_Main},
  SSHTunnel in 'SSHTunnel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Tf_Main, f_Main);
  Application.Run;
end.
