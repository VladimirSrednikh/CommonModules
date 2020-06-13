unit untMessageBox;

interface

uses
// VCL
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, Math;
// Commmon
//  LvvUtils,
//  LvvModalForm;

type
  TLabelEx = class(TLabel)
  private
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  end;

  TLabel = class(TLabelEx);

  TfrmMessageBox = class(TForm)
    lblText: TLabel;
    imgIcon: TImage;
    stText: TStaticText;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    fCloseModalResult: Integer;
    fFirstBtnIdx: Integer;
  protected
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
  public
    { Public declarations }
    procedure CreateControls;
  end;

function ShowMessageBox(const AText: string; AFlags: Longint): Integer;

function ShowCorrectMessageBox(const AText, ACaption: string; AFlags: Longint): Integer;

procedure ShowCorrectMessage(const Msg: string);

function ShowMessageBoxCB(const AText: string; AFlags: Longint; AStayOnTopCB: TNotifyEvent): Integer; // вариант для защиты от захвата фокуса другим приложением

type
  TLoadIconFunc = procedure (imgIcon: TImage; AIconType: NativeInt);

procedure LvvSetLoadIconFunc(AIconFunc: TLoadIconFunc);

implementation

{$R *.DFM}

procedure SetCorrectScreenCenterBounds(AForm: TForm; AChangePosition: boolean);
var
  AppScreen: TRect;
begin
  if AChangePosition then
    AForm.Position := poDesigned;
  SystemParametersInfo(SPI_GETWORKAREA, 0, @AppScreen, 0);

  AForm.SetBounds(
    AppScreen.Left + (AppScreen.Width - AForm.Width) div 2,
    AppScreen.Top + (AppScreen.Height - AForm.Height) div 2,
    AForm.Width,
    AForm.Height);
end;


var
  FLoadIconFunc: TLoadIconFunc;

procedure LvvSetLoadIconFunc(AIconFunc: TLoadIconFunc);
begin
  FLoadIconFunc := AIconFunc;
end;

function ShowMessageBox(const AText: string; AFlags: Longint): Integer;
var
  frm: TfrmMessageBox;
begin
  frm := TfrmMessageBox.Create(nil);
  try
    frm.Caption := Application.Title;
    frm.lblText.Caption := AText;
    frm.Tag := AFlags;
    frm.CreateControls;
    SetCorrectScreenCenterBounds(frm,true);
    Result := frm.ShowModal;
  finally
    frm.Free;
  end;
end;

function ShowMessageBoxCB(const AText: string; AFlags: Longint; AStayOnTopCB: TNotifyEvent): Integer;
var
  frm: TfrmMessageBox;
begin
  frm := TfrmMessageBox.Create(nil);
  try
    frm.Caption := Application.Title;
    frm.lblText.Caption := AText;
    frm.Tag := AFlags;
    frm.CreateControls;
    SetCorrectScreenCenterBounds(frm,true);
    Result := frm.ShowModal;
  finally
    frm.Free;
  end;
end;

function ShowCorrectMessageBox(const AText, ACaption: string; AFlags: Longint): Integer;
var
  frm: TfrmMessageBox;
begin
  frm := TfrmMessageBox.Create(nil);
  try
    frm.Caption := ACaption;
    frm.lblText.Caption := AText;
    frm.Tag := AFlags;
    frm.CreateControls;
    SetCorrectScreenCenterBounds(frm,true);
    Result := frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure ShowCorrectMessage(const Msg: string);
begin
  ShowCorrectMessageBox(Msg, Application.Title, MB_OK);
end;

procedure TfrmMessageBox.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if Visible then
    MessageBeep(Tag and $F);
end;

procedure TfrmMessageBox.FormShow(Sender: TObject);
begin
  Self.BringToFront;
  TWinControl(Controls[fFirstBtnIdx + (Tag shr 8) and $F]).SetFocus;
end;

type
  TRButton = record
    c: string;
    mr: TModalResult;
    def: boolean;
    can: boolean;
  end;

  TRButtons = array [1..255] of TRButton;

procedure TfrmMessageBox.CreateControls;
const
  C_Ok:               array [1..1] of TRButton = ((c: 'ОК'; mr: mrOk; def: true; can: true));
  C_OkCancel:         array [1..2] of TRButton = ((c: 'ОК'; mr: mrOk; def: true; can: false), (c: 'Отмена'; mr: mrCancel; def: false; can: true));
  C_YesNo:            array [1..2] of TRButton = ((c: 'Да'; mr: mrYes; def: true; can: false), (c: 'Нет'; mr: mrNo; def: false; can: true));
  C_YesNoCancel:      array [1..3] of TRButton = ((c: 'Да'; mr: mrYes; def: true; can: false), (c: 'Нет'; mr: mrNo; def: false; can: false), (c: 'Отмена'; mr: mrCancel; def: false; can: true));
  C_RetryCancel:      array [1..2] of TRButton = ((c: 'Повторить'; mr: mrRetry; def: true; can: false), (c: 'Отмена'; mr: mrCancel; def: false; can: true));
  C_AbortRetryIgnore: array [1..3] of TRButton = ((c: 'Прервать'; mr: mrAbort; def: false; can: false), (c: 'Повторить'; mr: mrRetry; def: false; can: false), (c: 'Игнорировать'; mr: mrIgnore; def: false; can: true));

  C_ButtonsFlag: array [1..6] of
    record
      fl: Integer;
      bc: Integer;
      b: ^TRButtons;
      d: Integer;
    end =
    (
      (fl: MB_OK;               bc: high(C_Ok) - low(C_Ok) + 1;                             b: @C_Ok;               d: mrOK),
      (fl: MB_OKCANCEL;         bc: high(C_OkCancel) - low(C_OkCancel) + 1;                 b: @C_OkCancel;         d: mrCancel),
      (fl: MB_YESNO;            bc: high(C_YesNo) - low(C_YesNo) + 1;                       b: @C_YesNo;            d: mrNo),
      (fl: MB_YESNOCANCEL;      bc: high(C_YesNoCancel) - low(C_YesNoCancel) + 1;           b: @C_YesNoCancel;      d: mrCancel),
      (fl: MB_RETRYCANCEL;      bc: high(C_RetryCancel) - low(C_RetryCancel) + 1;           b: @C_RetryCancel;      d: mrCancel),
      (fl: MB_ABORTRETRYIGNORE; bc: high(C_AbortRetryIgnore) - low(C_AbortRetryIgnore) + 1; b: @C_AbortRetryIgnore; d: mrIgnore)
    );

const
  C_Icons: array [1..5] of
    record
      fl: Integer;
      n: PWideChar;
    end =
    (
      (fl: MB_ICONERROR; n: IDI_ERROR),
      (fl: MB_ICONEXCLAMATION; n: IDI_EXCLAMATION),
      (fl: MB_ICONINFORMATION; n: IDI_INFORMATION),
      (fl: MB_ICONQUESTION; n: IDI_QUESTION),
      (fl: MB_ICONWARNING; n: IDI_WARNING)
    );

  procedure CreateIcon;
  var
    i: Integer;
    hi: Integer;
  begin
    for i := low(C_Icons) to high(C_Icons) do
      if C_Icons[i].fl = Tag and $F0 then
        Break;
    imgIcon.Tag := NativeInt(C_Icons[i].n);
    if Assigned(FLoadIconFunc) then
      FLoadIconFunc(imgIcon, imgIcon.Tag)
    else
    begin
      hi := LoadIcon(0, C_Icons[i].n);
      try
        with imgIcon.Picture.Bitmap do
        begin
          Height := GetSystemMetrics(SM_CYICON);
          Width  := GetSystemMetrics(SM_CXICON);
          Canvas.Brush.Color := clBtnFace;
          Canvas.FillRect(Canvas.ClipRect);
          DrawIcon(Canvas.Handle, 0, 0, hi);
        end;
      finally
        DestroyIcon(hi);
      end;
    end;
  end;

var
  ButI: Integer;

  procedure CreateButtons;
  var
    i: Integer;
    b: TButton;
  begin
    ButI := low(C_ButtonsFlag);
    for i := low(C_ButtonsFlag) to high(C_ButtonsFlag) do
      if C_ButtonsFlag[i].fl = Tag and $0F then
      begin
        ButI := i;
        Break;
      end;

    fCloseModalResult := C_ButtonsFlag[ButI].d; // Это на случай когда нажимается "крестик"

    for i := 1 to C_ButtonsFlag[ButI].bc do
    begin
      b := TButton.Create(Self);
      b.Name := 'btn' + inttostr(i);
      b.Parent := Self;
      b.Caption := C_ButtonsFlag[ButI].b^[i].c;
      b.ModalResult := C_ButtonsFlag[ButI].b^[i].mr;
      b.Default := C_ButtonsFlag[ButI].b^[i].def;
      b.Cancel := C_ButtonsFlag[ButI].b^[i].can;

      b.Width := 80;
//      b.SetBounds(b.Left, b.Top, 80, 25);
    end;
  end;

  procedure SetSizeWindow;
  var
    w: Integer;
  begin
    w  := MaxIntValue([
      lblText.Left + lblText.Width - imgIcon.Left,
      (C_ButtonsFlag[ButI].bc * 9 - 1) * Controls[fFirstBtnIdx].Width div 8
    ]) + imgIcon.Left * 2;
    if w > Screen.Width - 20 then
    begin
      ClientWidth := Screen.Width - 20;
      lblText.Width := ClientWidth - imgIcon.Left * 2 - lblText.Left + imgIcon.Left;
      lblText.WordWrap := true;
    end
    else
      ClientWidth := w;

    ClientHeight := MaxIntValue([
      lblText.Top + lblText.Height,
      imgIcon.Top + imgIcon.Height
    ]) + Controls[fFirstBtnIdx].Height * 6 div 4;

    if Assigned(FLoadIconFunc) then
      FLoadIconFunc(imgIcon, imgIcon.Tag);// С обновленным размером

    imgIcon.Top := (lblText.Top + (lblText.Height div 2)) - (imgIcon.Height div 2);
  end;

  procedure PlaceButtons;
  var
    i, l: Integer;
  begin
    l := (ClientWidth - (C_ButtonsFlag[ButI].bc * 9 - 1) * Controls[fFirstBtnIdx].Width div 8) div 2;
    for i := fFirstBtnIdx to ControlCount - 1 do
    begin
      Controls[i].SetBounds(l, ClientHeight - Controls[i].Height * 5 div 4, Controls[i].Width, Controls[i].Height);
      Inc(l, Controls[i].Width * 9 div 8);
    end;
  end;

begin
  CreateIcon;
  CreateButtons;
//  SetParentFontForm(Self, LvvMainFont, 0, 0);

  SetSizeWindow;
  PlaceButtons;
end;

procedure TfrmMessageBox.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if (ModalResult = mrCancel) and (fCloseModalResult <> mrCancel) then
    ModalResult := fCloseModalResult;
end;

procedure TfrmMessageBox.FormCreate(Sender: TObject);
begin
  fFirstBtnIdx := ControlCount;
end;

{ TLabelEx }

procedure TLabelEx.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if Assigned(Owner) and (Owner is TfrmMessageBox) then
    (Owner as TfrmMessageBox).stText.Caption := Caption;
end;

end.
