// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2018 Salvador Diaz Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uCEFUrlRequestClientComponent;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$IFNDEF CPUX64}
  {$ALIGN ON}
  {$MINENUMSIZE 4}
{$ENDIF}

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows, WinApi.Messages, WinApi.ActiveX,{$ENDIF}
    System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.Forms, System.Math,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} Classes, Forms, Controls, Graphics, ActiveX, Math,
    {$IFDEF FPC}
    LCLProc, LCLType, LCLIntf, LResources, LMessages, InterfaceBase,
    {$ELSE}
    Messages,
    {$ENDIF}
  {$ENDIF}
  uCEFTypes, uCEFInterfaces, uCEFUrlRequestClientEvents, uCEFUrlrequestClient, uCEFUrlRequest;

type
  TCEFUrlRequestClientComponent = class(TComponent, ICEFUrlRequestClientEvents)
    protected
      FClient               : ICefUrlrequestClient;
      FThreadID             : TCefThreadId;

      FOnRequestComplete    : TOnRequestComplete;
      FOnUploadProgress     : TOnUploadProgress;
      FOnDownloadProgress   : TOnDownloadProgress;
      FOnDownloadData       : TOnDownloadData;
      FOnGetAuthCredentials : TOnGetAuthCredentials;
      FOnCreateURLRequest   : TNotifyEvent;

      // ICefUrlrequestClient
      procedure doOnRequestComplete(const request: ICefUrlRequest);
      procedure doOnUploadProgress(const request: ICefUrlRequest; current, total: Int64);
      procedure doOnDownloadProgress(const request: ICefUrlRequest; current, total: Int64);
      procedure doOnDownloadData(const request: ICefUrlRequest; data: Pointer; dataLength: NativeUInt);
      function  doOnGetAuthCredentials(isProxy: Boolean; const host: ustring; port: Integer; const realm, scheme: ustring; const callback: ICefAuthCallback): Boolean;

      // Custom
      procedure doOnCreateURLRequest;

    public
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure   AfterConstruction; override;

      procedure   AddURLRequest;

      property Client               : ICefUrlrequestClient   read FClient;
      property ThreadID             : TCefThreadId           read FThreadID              write FThreadID;

    published
      property OnRequestComplete    : TOnRequestComplete     read FOnRequestComplete     write FOnRequestComplete;
      property OnUploadProgress     : TOnUploadProgress      read FOnUploadProgress      write FOnUploadProgress;
      property OnDownloadProgress   : TOnDownloadProgress    read FOnDownloadProgress    write FOnDownloadProgress;
      property OnDownloadData       : TOnDownloadData        read FOnDownloadData        write FOnDownloadData;
      property OnGetAuthCredentials : TOnGetAuthCredentials  read FOnGetAuthCredentials  write FOnGetAuthCredentials;
      property OnCreateURLRequest   : TNotifyEvent           read FOnCreateURLRequest    write FOnCreateURLRequest;
  end;

{$IFDEF FPC}
procedure Register;
{$ENDIF}

implementation

uses
  {$IFDEF DELPHI16_UP}
  System.SysUtils,
  {$ELSE}
  SysUtils,
  {$ENDIF}
  uCEFRequest, uCEFTask, uCEFMiscFunctions;


constructor TCEFUrlRequestClientComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FClient               := nil;
  FThreadID             := TID_UI;
  FOnRequestComplete    := nil;
  FOnUploadProgress     := nil;
  FOnDownloadProgress   := nil;
  FOnDownloadData       := nil;
  FOnGetAuthCredentials := nil;
  FOnCreateURLRequest   := nil;
end;

destructor TCEFUrlRequestClientComponent.Destroy;
begin
  FClient := nil;

  inherited Destroy;
end;

procedure TCEFUrlRequestClientComponent.AfterConstruction;
begin
  inherited AfterConstruction;

  if not(csDesigning in ComponentState) then
    FClient := TCustomCefUrlrequestClient.Create(self);
end;

procedure TCEFUrlRequestClientComponent.doOnRequestComplete(const request: ICefUrlRequest);
begin
  if assigned(FOnRequestComplete) then FOnRequestComplete(self, request);
end;

procedure TCEFUrlRequestClientComponent.doOnUploadProgress(const request: ICefUrlRequest; current, total: Int64);
begin
  if assigned(FOnUploadProgress) then FOnUploadProgress(self, request, current, total);
end;

procedure TCEFUrlRequestClientComponent.doOnDownloadProgress(const request: ICefUrlRequest; current, total: Int64);
begin
  if assigned(FOnDownloadProgress) then FOnDownloadProgress(self, request, current, total);
end;

procedure TCEFUrlRequestClientComponent.doOnDownloadData(const request: ICefUrlRequest; data: Pointer; dataLength: NativeUInt);
begin
  if assigned(FOnDownloadData) then FOnDownloadData(self, request, data, datalength);
end;

function TCEFUrlRequestClientComponent.doOnGetAuthCredentials(isProxy: Boolean; const host: ustring; port: Integer; const realm, scheme: ustring; const callback: ICefAuthCallback): Boolean;
begin
  Result := False;

  if assigned(FOnGetAuthCredentials) then FOnGetAuthCredentials(self, isProxy, host, port, realm, scheme, callback, Result);
end;

procedure TCEFUrlRequestClientComponent.doOnCreateURLRequest;
begin
  if assigned(FOnCreateURLRequest) then FOnCreateURLRequest(self);
end;

procedure TCEFUrlRequestClientComponent.AddURLRequest;
var
  TempTask : ICefTask;
begin
  TempTask := TCefURLRequestTask.Create(self);
  CefPostTask(FThreadID, TempTask);
end;

{$IFDEF FPC}
procedure Register;
begin
  {$I res/tcefurlrequestclientcomponent.lrs}
  RegisterComponents('Chromium', [TCEFUrlRequestClientComponent]);
end;
{$ENDIF}

end.
