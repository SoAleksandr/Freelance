unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ImgList, ExtCtrls, RxGIF;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    ImageList1: TImageList;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    Image1: TImage;
    Help1: TMenuItem;
    N9: TMenuItem;
    procedure N4Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Unit2, Unit3, Unit4;

{$R *.dfm}

procedure TForm1.N4Click(Sender: TObject);
begin
Form4.ShowModal;
end;

procedure TForm1.N5Click(Sender: TObject);
begin
form2.Show;
end;

procedure TForm1.N6Click(Sender: TObject);
begin
form3.Show;
end;

procedure TForm1.N7Click(Sender: TObject);
begin
form2.Close;
form3.Close;
end;

procedure TForm1.N8Click(Sender: TObject);
begin
Close;
end;

end.
