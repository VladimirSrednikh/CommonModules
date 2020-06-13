unit ProjectFuncs;

interface

uses System.StrUtils;

function GetParamVal(const ParamName: string): string;

implementation

function GetParamVal(const ParamName: string): string;
var
  i: Integer;
begin
  for i := 1 to ParamCount do
    if AnsiStartsText(ParamName, ParamStr(i)) then
       Exit(Copy(ParamStr(i), Length(ParamName) + 1, Length(ParamStr(i)) - (Length(ParamName))))
end;

end.
