unit system.config;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
{$endif}

interface

uses
  Classes, SysUtils;

type

  { TProduto }

  TProduto = class
  public
    class function PrecoPorEmpresa: Boolean;
  end;

  { TConfiguration }

  TConfig = class
  private
    class var FInstance: TConfig;
    constructor Create;
  public
    class procedure Initialize;
    //class procedure FreeInstance;
    class var Produto: TProduto;
  end;

implementation

{ TConfiguration }

constructor TConfig.Create;
begin
  try
    try

    finally
    end;
  except on e: Exception do
  begin
    Writeln(ErrOutput, 'Error initializing system config: ' + e.Message);
  end; end;
end;

class procedure TConfig.Initialize;
begin
  FInstance := TConfig.Create;
end;

{ TProduto }

class function TProduto.PrecoPorEmpresa: Boolean;
begin
  Result := False;
end;

//class procedure TConfig.FreeInstance;
//begin
//  FInstance.Free;
//end;
//
end.

