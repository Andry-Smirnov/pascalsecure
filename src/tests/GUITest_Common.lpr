program GUITest_Common;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, TestSecurityManagerSchema, pascalsecure,
  TestBasicUserManagement, TestControlsManager, MockSecureControl;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

