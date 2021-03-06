{*******************************************************************************
  Copyright (C) Christian Ulrich info@cu-tec.de

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or commercial alternative
  contact us for more information

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
*******************************************************************************}
unit uFindTransaction;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ButtonPanel, uBaseDBClasses, uFilterFrame, uAccounting,uBaseDatasetInterfaces;

type
  TfFindTransaction = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbName: TCheckBox;
    cbAmount: TCheckBox;
    cbDate: TCheckBox;
    Label1: TLabel;
    Panel1: TPanel;
    procedure FilterChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FDataSet: TBaseDBDataSet;
    FList: TfFilter;
    FAccountExchange : TAccountExchange;
  public
    { public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy;override;
    function Execute(AccountExchange : TAccountExchange) : Boolean;
    property DataSet : TBaseDBDataSet read FDataSet write FDataSet;
  end;

var
  fFindTransaction: TfFindTransaction;

implementation
{$R *.lfm}
uses uData,Utils,uBaseDBInterface,uBookAccounting,uPerson,Variants;

procedure TfFindTransaction.FilterChange(Sender: TObject);
var
  aFilter : string = '';
  aName: String;
  aName1: String;
  function FloatToSQL(aFloat : real) : string;
  begin
    Result := StringReplace(FloatToStr(aFloat),',','.',[rfReplaceAll]);
    //TODO:maybe not correct for other formating settings than germany
  end;

begin
  aName := StringReplace(FAccountExchange.FieldByName('NAME').AsString,',',' ',[rfReplaceAll]);
  aName1 := UpperCase(copy(aName,0,pos(' ',aName)-1));
  aName := UpperCase(copy(aName,rpos(' ',aName)+1,length(aName)));
  with FAccountExchange.DataSet as IBaseDBFilter do
    begin
      aFilter := Data.ProcessTerm(Data.QuoteField('PAYEDON')+'=''''');
      if cbName.Checked then
        aFilter := aFilter+' and ('+Data.ProcessTerm(Data.QuoteField('CUSTNAME')+'='+Data.QuoteValue('*'+aName+'*'))+' or '+Data.ProcessTerm(Data.QuoteField('CUSTNAME')+'='+Data.QuoteValue('*'+aName1+'*'))+')';
      if cbAmount.Checked then
        aFilter := aFilter+' and ('+Data.QuoteField('GROSSPRICE')+'>='''+FloatToSQL(abs(FAccountExchange.FieldByName('VALUE').AsFloat*0.9))+''' and '+Data.QuoteField('GROSSPRICE')+'<='''+FloatToSQL(abs(FAccountExchange.FieldByName('VALUE').AsFloat*1.1))+''')';
      if cbDate.Checked then
        aFilter := aFilter+' and ('+Data.QuoteField('ODATE')+'>='+Data.DateToFilter(FAccountExchange.FieldByName('VALUEDATE').AsDateTime-7)+' and '+Data.QuoteField('ODATE')+'<='+Data.DateToFilter(FAccountExchange.FieldByName('VALUEDATE').AsDateTime+7)+')';
    end;
  FList.BaseFilter:=aFilter;
  FList.acFilter.Execute;
end;

procedure TfFindTransaction.FormShow(Sender: TObject);
begin
  FList.SetActive;
end;

constructor TfFindTransaction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TfFilter.Create(Self);
  Dataset := TAccountingJournal.Create(nil);
  with FList do
    begin
      FilterType:='SA';
      DefaultRows:='GLOBALWIDTH:%;PAYEDON:100;ORDERNO:100;STATUS:30;NUMBER:100;ODATE:70;CUSTNO:70;CUSTNAME:100;GROSSPRICE:100;';
      Parent := Self;
      Align := alClient;
      Editable:=False;
      pTop.Visible:=False;
      FList.DataSet := fFindTransaction.DataSet;
      Show;
    end;
end;

destructor TfFindTransaction.Destroy;
begin
  FList.Free;
//  DataSet.Destroy;
  inherited Destroy;
end;

function TfFindTransaction.Execute(AccountExchange : TAccountExchange): Boolean;
var
  aCustomer : TPerson;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfFindTransaction,fFindTransaction);
      Self := fFindTransaction;
    end;
  FAccountExchange := AccountExchange;
  FilterChange(nil);
  Result := Showmodal = mrOK;
  if Result and (DataSet.Count > 0) then
    begin
      begin
        fBookAccounting.SetLanguage;
        fBookAccounting.Accountingjournal := TAccountingJournal(DataSet);
        fBookAccounting.AccountExchange := FAccountExchange;
        if not fBookAccounting.Execute(abs(FAccountExchange.FieldByName('VALUE').AsFloat),FAccountExchange.FieldByName('VALUEDATE').AsDateTime,Data.BuildLink(FAccountExchange.DataSet)) then exit;
        aCustomer := TPerson.CreateEx(Self,Data);
        aCustomer.Select(DataSet.FieldByName('CUSTNO').AsString);
        aCustomer.Open;
        if aCustomer.Count > 0 then
          begin
            aCustomer.Banking.Open;
            if not aCustomer.Banking.DataSet.Locate('SORTCODE;ACCOUNT',VarArrayOf([FAccountExchange.FieldByName('RSORTCODE').AsString,FAccountExchange.FieldByName('RACCOUNTNO').AsString]),[]) then
              begin
                aCustomer.Banking.DataSet.Append;
                aCustomer.Banking.FieldByName('SORTCODE').AsString:= FAccountExchange.FieldByName('RSORTCODE').AsString;
                aCustomer.Banking.FieldByName('ACCOUNT').AsString:= FAccountExchange.FieldByName('RACCOUNTNO').AsString;
                aCustomer.Banking.DataSet.Post;
              end;
          end;
        aCustomer.Free;
      end;
    end;
//  FreeAndNil(fFindTransaction);
end;

end.

