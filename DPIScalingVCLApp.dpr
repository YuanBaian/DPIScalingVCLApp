program DPIScalingVCLApp;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {MainForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainFormInstance);
  Application.Run;
end.
