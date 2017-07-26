unit security.manager.basic_user_management;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type
  TUserChangedEvent = procedure(Sender:TObject; const OldUsername, NewUserName:String) of object;

  TFPGStringList = specialize TFPGList<String>;

  { TpSCADABasicUserManagement }

  TBasicUserManagement = class(TComponent)
  protected
    FLoggedUser:Boolean;
    FCurrentUserName,
    FCurrentUserLogin:String;
    FUID:Integer;
    FLoggedSince:TDateTime;
    FInactiveTimeOut:Cardinal;
    FLoginRetries:Cardinal;
    FFrozenTime:Cardinal;

    FSuccessfulLogin:TNotifyEvent;
    FFailureLogin:TNotifyEvent;
    FUserChanged:TUserChangedEvent;

    FRegisteredSecurityCodes:TFPGStringList;

    function  GetLoginTime:TDateTime;
    procedure SetInactiveTimeOut(AValue: Cardinal); virtual;
    function  GetUID: Integer;
    procedure DoUserChanged; virtual;

    procedure DoSuccessfulLogin; virtual;
    procedure DoFailureLogin; virtual;

    function CheckUserAndPassword(User, Pass:String; var UserID:Integer; LoginAction:Boolean):Boolean; virtual; abstract;

    function GetLoggedUser:Boolean; virtual;
    function GetCurrentUserName:String; virtual;
    function GetCurrentUserLogin:String; virtual;

    //read only properties.
    property LoggedSince:TDateTime read GetLoginTime;

    //read-write properties.
    //property VirtualKeyboardType:TVKType read FVirtualKeyboardType write FVirtualKeyboardType;
    property InactiveTimeout:Cardinal read FInactiveTimeOut write SetInactiveTimeOut;
    property LoginRetries:Cardinal read FLoginRetries write FLoginRetries;
    property LoginFrozenTime:Cardinal read  FFrozenTime write FFrozenTime;

    property SuccessfulLogin:TNotifyEvent read FSuccessfulLogin write FSuccessfulLogin;
    property FailureLogin:TNotifyEvent read FFailureLogin write FFailureLogin;
    property UserChanged:TUserChangedEvent read FUserChanged write FUserChanged;
    function CanAccess(sc:String; aUID:Integer):Boolean; virtual; abstract; overload;
  public
    constructor Create(AOwner:TComponent); override;
    destructor  Destroy; override;
    function    Login:Boolean; virtual; abstract; overload;
    function    Login(Userlogin, userpassword: String; var UID: Integer):Boolean; virtual;
    procedure   Logout; virtual;
    procedure   Manage; virtual; abstract;

    //Security codes management
    procedure   ValidateSecurityCode(sc:String); virtual; abstract;
    function    SecurityCodeExists(sc:String):Boolean; virtual;
    procedure   RegisterSecurityCode(sc:String); virtual;
    procedure   UnregisterSecurityCode(sc:String); virtual;

    function    CanAccess(sc:String):Boolean; virtual; abstract;
    function    GetRegisteredAccessCodes:TFPGStringList; virtual;

    function    CheckIfUserIsAllowed(sc: String; RequireUserLogin: Boolean; var userlogin: String): Boolean; virtual; abstract;

    //read only properties.
    property UID:Integer read GetUID;
    property UserLogged:Boolean read GetLoggedUser;
    property CurrentUserName:String read GetCurrentUserName;
    property CurrentUserLogin:String read GetCurrentUserLogin;
  end;

implementation

uses security.exceptions,
     security.manager.controls_manager;

constructor TBasicUserManagement.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);

  if GetControlSecurityManager.UserManagement=nil then
    GetControlSecurityManager.UserManagement:=Self
  else
    raise EUserManagementIsSet.Create;

  FLoggedUser:=false;
  FCurrentUserName:='';
  FCurrentUserLogin:='';
  FUID:=-1;
  FLoggedSince:=Now;

  FRegisteredSecurityCodes:=TFPGStringList.Create;
end;

destructor  TBasicUserManagement.Destroy;
begin
  if GetControlSecurityManager.UserManagement=Self then
    GetControlSecurityManager.UserManagement:=nil;

  if FRegisteredSecurityCodes<>nil then
    FRegisteredSecurityCodes.Destroy;
  inherited Destroy;
end;

function TBasicUserManagement.Login(Userlogin, userpassword: String; var UID:Integer):Boolean; overload;
begin
  Result:=CheckUserAndPassword(Userlogin, userpassword, UID, true);
  if Result then begin
    FLoggedUser:=true;
    FUID:=UID;
    FCurrentUserLogin:=Userlogin;
    FLoggedSince:=Now;
    Result:=true;
    GetControlSecurityManager.UpdateControls;
    DoSuccessfulLogin;
  end;
end;

procedure   TBasicUserManagement.Logout;
begin
  FLoggedUser:=false;
  FCurrentUserName:='';
  FCurrentUserLogin:='';
  FUID:=-1;
  FLoggedSince:=Now;
  GetControlSecurityManager.UpdateControls;
end;

function    TBasicUserManagement.SecurityCodeExists(sc:String):Boolean;
begin
  Result:=FRegisteredSecurityCodes.IndexOf(sc)>=0;
end;

procedure   TBasicUserManagement.RegisterSecurityCode(sc:String);
begin
  if Not SecurityCodeExists(sc) then
    FRegisteredSecurityCodes.Add(sc);
end;

procedure   TBasicUserManagement.UnregisterSecurityCode(sc:String);
begin
  if SecurityCodeExists(sc) then
    FRegisteredSecurityCodes.Delete(FRegisteredSecurityCodes.IndexOf(sc));
end;

function TBasicUserManagement.GetRegisteredAccessCodes: TFPGStringList;
begin
  Result:=TFPGStringList.Create;
  Result.Assign(FRegisteredSecurityCodes);
end;

function TBasicUserManagement.GetUID: Integer;
begin
  Result:=FUID;
end;

function    TBasicUserManagement.GetLoginTime:TDateTime;
begin
  if FLoggedUser then
    Result:=FLoggedSince
  else
    Result:=Now;
end;

procedure TBasicUserManagement.SetInactiveTimeOut(AValue: Cardinal);
begin
  FInactiveTimeOut:=AValue;
end;

function TBasicUserManagement.GetLoggedUser:Boolean;
begin
  Result:=FLoggedUser;
end;

function TBasicUserManagement.GetCurrentUserName:String;
begin
  Result:=FCurrentUserName;
end;

function TBasicUserManagement.GetCurrentUserLogin:String;
begin
  Result:=FCurrentUserLogin;
end;

procedure TBasicUserManagement.DoSuccessfulLogin;
begin
  if Assigned(FSuccessfulLogin) then
    FSuccessfulLogin(Self);
end;

procedure TBasicUserManagement.DoFailureLogin;
begin
  if Assigned(FFailureLogin) then
    FFailureLogin(Self);
end;

procedure TBasicUserManagement.DoUserChanged;
begin
  if Assigned(FUserChanged) then
    try
      FUserChanged(Self, FCurrentUserLogin, GetCurrentUserLogin);
    finally
    end;
end;

end.

