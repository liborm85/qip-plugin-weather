unit W_plugin_info;

interface

uses SysUtils, Classes, Dialogs, Graphics, Windows, Forms, ExtCtrls;

const
  W_SDK_VER_MAJOR = 0;
  W_SDK_VER_MINOR = 1;

type

  {Result Data}
  TResultData = record
    OK                : Boolean;
    parString         : String;
  end;


  {Plugin info}
  TWPluginInfo = record
    SDKVerMajor       : Word;
    SDKVerMinor       : Word;
    PluginVerMajor    : Word;
    PluginVerMinor    : Word;
    PluginName        : WideString;
    PluginAuthor      : WideString;
    PluginType        : Integer;
  end;

  {Servers}
  TSLServers = class
    public
      ServerID           : WideString;
      ServerName         : WideString;
      ServerIcon         : TImage;
    end;

  {W Info Units}
  TWInfoUnits = record
    Value               : WideString;
    ValueUnit           : WideString;
  end;

  {Weather Info}
  TSLWeather = class
    public
      LocalTime           : WideString;
      LastUpdate          : WideString;
      Temperature         : TWInfoUnits;
      Condition           : WideString;
      ChanceOfPrec        : WideString;
      Humidity            : WideString;
      DewPoint            : TWInfoUnits;
      WindSpeed           : TWInfoUnits;
      WindDirection       : WideString;
      Pressure            : TWInfoUnits;
      PressureChange      : WideString;
      Visibility          : TWInfoUnits;
      UV                  : WideString;
      Sunrise             : WideString;
      Sunset              : WideString;
    end;

  { Next Day Weather Info}
  TSLNextDayWeather = class
    public
      LocalTime           : WideString;
      LastUpdate          : WideString;
      Day                 : WideString;
      Date                : WideString;
      TemperatureHigh     : TWInfoUnits;
      TemperatureLow      : TWInfoUnits;
      Condition           : WideString;
      ChanceOfPrec        : WideString;
{      Humidity            : WideString;
      DewPoint            : TWInfoUnits;
      WindSpeed           : TWInfoUnits;
      WindDirection       : WideString;
      Pressure            : TWInfoUnits;
      PressureChange      : WideString;
      Visibility          : TWInfoUnits;
      UV                  : WideString;   }
    end;

  {Found Places}
  TSLFoundPlaces = class
    public
      Name               : WideString;
      ID                 : WideString;
    end;


  { Position Info }
  TPositionInfo = record
    Info              : WideString;
    Int64_1           : Int64;
    Int64_2           : Int64;
    Int64_3           : Int64;
    Int64_4           : Int64;
    Int64_5           : Int64;
  end;

  { Set Conf }
  TSetConf = record
    TempPath          : WideString;
    Timeout           : Integer;
    Proxy_Use         : Boolean;
    Proxy_Host        : WideString;
    Proxy_Port        : Integer;
    Proxy_User        : WideString;
    Proxy_Pass        : WideString;
  end;

var WConf: TSetConf;
    Timeout: Integer;

implementation

end.
