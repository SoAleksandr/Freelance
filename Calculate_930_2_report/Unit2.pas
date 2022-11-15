unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, RzLabel;

type
  TForm2 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit14: TEdit;
    Edit15: TEdit;
    Edit16: TEdit;
    Edit17: TEdit;
    Saldo: TEdit;
    Nal_Kredit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    RzLabel1: TRzLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.BitBtn1Click(Sender: TObject);
var
a,b,c,d,e,f,g,h,i,j,k,l,m,
saldo_morning,saldo_evening,payment_today,shipment_today,payment,nal_payment_kredit: extended;
begin
try
a := StrToFloat(Edit1.text);
b := StrToFloat(Edit2.text);
c := StrToFloat(Edit3.text);
d := StrToFloat(Edit4.text);
e := StrToFloat(Edit5.text);
f := StrToFloat(Edit6.text);
g := StrToFloat(Edit7.text);
h := StrToFloat(Edit8.text);
i := StrToFloat(Edit9.text);
j := StrToFloat(Edit10.text);
k := StrToFloat(Edit11.text);
l := StrToFloat(Edit12.text);
m := StrToFloat(Edit13.text);
saldo_morning := StrToFloat(saldo.text);
nal_payment_kredit := StrToFloat(Nal_Kredit.text);

//---------------------------Результат вычисления-------------------------------

//Сальдо на вечер
saldo_evening := ((saldo_morning + j) - g) - (m - l);
Edit14.Text := FloatToStr(saldo_evening);

//Оплачено сегодня
payment_today := e + g + j;
Edit15.Text := FloatToStr(payment_today);

//Отгружено сегодня
shipment_today := e + g + k;
Edit16.Text := FloatToStr(shipment_today);

//Оплата
payment := c + nal_payment_kredit;
Edit17.Text := FloatToStr(payment);

except
MessageBox(handle,pchar('Ошибка ввода! Поля ввода не должны быть пустыми. Введите в пустые ячейки 0'),pchar('MessageBox'),16);
end;

//Проверка
//Сравнение должной суммы с результатом вычисления
if ((b - a)*(-1)) - (((i + k) - (h + j))*(-1)) < 0 then RzLabel1.Blinking := true;
//MessageBox(handle,pchar('Ошибка ввода! Вероятно вы не ввели сумму (сальдо на вечер).'),pchar('MessageBox'),16);
end;

procedure TForm2.BitBtn2Click(Sender: TObject);
begin
Edit1.Clear;
Edit2.Clear;
Edit3.Clear;
Edit4.Clear;
Edit5.Clear;
Edit6.Clear;
Edit7.Clear;
Edit8.Clear;
Edit9.Clear;
Edit10.Clear;
Edit11.Clear;
Edit12.Clear;
Edit13.Clear;
Edit14.Clear;
Edit15.Clear;
Edit16.Clear;
Edit17.Clear;
Nal_Kredit.Clear;
Saldo.Clear;
RzLabel1.Blinking := false;
end;

end.
