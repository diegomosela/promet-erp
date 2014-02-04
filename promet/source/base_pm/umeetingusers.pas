unit umeetingusers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ExtCtrls, DbCtrls, Buttons,
  ActnList, uExtControls, db, uPrometFramesInplaceDB, uFilterFrame,uBaseDbClasses,
  uBaseDBInterface,uIntfStrConsts,Grids;

type
  TfMeetingUsers = class(TPrometInplaceDBFrame)
    acCopyToClipboard: TAction;
    acFilter: TAction;
    acPasteLinks: TAction;
    acShowInOrder: TAction;
    ActionList1: TActionList;
    bAddPos1: TSpeedButton;
    Bevel1: TBevel;
    Datasource: TDatasource;
    dnContacts: TDBNavigator;
    ExtRotatedLabel1: TExtRotatedLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    pCont: TPanel;
    procedure bAddPos1Click(Sender: TObject);
    procedure FContListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FContListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    function fSearchOpenProjectItem(aLink: string): Boolean;
  private
    { private declarations }
    FContList: TfFilter;
    FEditable: Boolean;
  public
    { public declarations }
    procedure SetDataSet(const AValue: TBaseDBDataSet);override;
    procedure SetRights(Editable : Boolean);override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy;override;
    procedure ShowFrame; override;
  end;

implementation
uses uSearch,uData;
{$R *.lfm}

procedure TfMeetingUsers.FContListDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := False;
  if Assigned(fSearch) and (Source = fSearch.sgResults) then
    begin
      with fSearch.sgResults do
        Accept := copy(trim(fSearch.GetLink),0,5) = 'USERS';
    end;
end;

function TfMeetingUsers.fSearchOpenProjectItem(aLink: string): Boolean;
var
  aUsers: TUser;
begin
  DataSet.DataSet.Append;
  DataSet.DataSet.FieldByName('NAME').AsString:=Data.GetLinkDesc(aLink);
  aUsers := TUser.Create(nil,Data);
  aUsers.SelectFromLink(aLink);
  aUsers.Open;
  if aUsers.Count>0 then
    begin
      DataSet.DataSet.FieldByName('USER_ID').AsVariant:=aUsers.Id.AsVariant;
      DataSet.DataSet.FieldByName('IDCODE').AsString:=aUsers.IDCode.AsString;
    end;
  aUsers.Free;
  DataSet.DataSet.Post;
end;

procedure TfMeetingUsers.FContListDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  aRec: String;
  OldFilter: String;
  aLink: String;
  aLinkDesc: String;
  aIcon: Integer;
  aUsers: TUser;
begin
  if Assigned(fSearch) and (Source = fSearch.sgResults) then
    begin
      aLink := fSearch.GetLink;
      aLinkDesc := Data.GetLinkDesc(aLink);
      aIcon := Data.GetLinkIcon(aLink);
      with DataSet.DataSet do
        begin
          Insert;
          FieldByName('NAME').AsString := aLinkDesc;
          aUsers := TUser.Create(nil,Data);
          aUsers.SelectFromLink(aLink);
          aUsers.Open;
          if aUsers.Count>0 then
            begin
              DataSet.DataSet.FieldByName('USER_ID').AsVariant:=aUsers.Id.AsVariant;
              DataSet.DataSet.FieldByName('IDCODE').AsString:=aUsers.IDCode.AsString;
            end;
          aUsers.Free;
          Post;
        end;
    end;
end;

procedure TfMeetingUsers.bAddPos1Click(Sender: TObject);
var
  i: Integer;
begin
  fSearch.SetLanguage;
  i := 0;
  while i < fSearch.cbSearchType.Count do
    begin
      if (fSearch.cbSearchType.Items[i] <> strUsers)
      and (fSearch.cbSearchType.Items[i] <> strCustomers)
      then
        fSearch.cbSearchType.Items.Delete(i)
      else
        inc(i);
    end;
  fSearch.eContains.Clear;
  fSearch.sgResults.RowCount:=1;
  fSearch.OnOpenItem:=@fSearchOpenProjectItem;
  fSearch.Execute(True,'MEETU','');
  fSearch.SetLanguage;
end;

procedure TfMeetingUsers.SetDataSet(const AValue: TBaseDBDataSet);
var
  i: Integer;
begin
  inherited SetDataSet(AValue);
  with FContList do
    begin
      with AValue.DataSet as IBaseDbFilter do
        FContList.DefaultFilter:=Filter;
    end;
  FContList.DataSet := AValue;
  DataSource.DataSet := AValue.DataSet;
  with FContList do
    for i := 0 to gList.Columns.Count-1 do
      begin
        if gList.Columns[i].FieldName='ACTIVE' then
          begin
            gList.Columns[i].ButtonStyle:=cbsCheckboxColumn;
            gList.Columns[i].ValueChecked:='Y';
            gList.Columns[i].ValueUnChecked:='N';
          end;
      end;
end;

procedure TfMeetingUsers.SetRights(Editable: Boolean);
begin
  FEditable := Editable;
  bAddPos1.Enabled := Editable;
  dnContacts.Enabled:=Editable;
  FContList.Editable:=Editable;
end;

constructor TfMeetingUsers.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContList := TfFilter.Create(Self);
  with FContList do
    begin
      FilterType:='PUSER';
      DefaultRows:='GLOBALWIDTH:%;NAME:200;ACTIVE:30;NOTE:200;';
      Parent := pCont;
      Align := alClient;
      PTop.Visible := False;
      Editable := True;
      gList.CachedEditing:=True;
      Show;
    end;
  FContList.gList.OnDragOver:=@FContListDragOver;
  FContList.gList.OnDragDrop:=@FContListDragDrop;
end;

destructor TfMeetingUsers.Destroy;
begin
  if Assigned(FContList) then
    begin
      FContList.DataSet := nil;
      FContList.Free;
    end;
  FDataSet := nil;
  inherited Destroy;
end;

procedure TfMeetingUsers.ShowFrame;
begin
  inherited ShowFrame;
  FContList.SetActive;
end;

end.

