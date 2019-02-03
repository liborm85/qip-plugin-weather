unit W_plugin;

interface

uses SysUtils, Classes, Dialogs, Graphics, Windows, Forms, W_plugin_info,
     WinInet, mshtml, SHDocVw, ExtCtrls, TextSearch, DownloadFile, Convs;


const
  W_PLUGIN_VER_MAJOR = 0;
  W_PLUGIN_VER_MINOR = 7;
  W_PLUGIN_NAME      : WideString = 'wetter.com';
  W_PLUGIN_AUTHOR    : WideString = 'Lms';
{  W_PLUGIN_TYPE      : Integer = 0;  - NOT WORK}



implementation

(* === Plugin Info - PLUGIN PROCEDURE ======================================= *)
function GetPluginInfo(): TWPluginInfo; stdcall;
begin
  Timeout := 5000;

  Result.SDKVerMajor    := W_SDK_VER_MAJOR;
  Result.SDKVerMinor    := W_SDK_VER_MINOR;
  Result.PluginVerMajor := W_PLUGIN_VER_MAJOR;
  Result.PluginVerMinor := W_PLUGIN_VER_MINOR;
  Result.PluginName     := W_PLUGIN_NAME;
  Result.PluginAuthor   := W_PLUGIN_AUTHOR;
{  Result.PluginType     := W_PLUGIN_TYPE;  - NOT WORK}

end;

(* === Set Conf ============================================================= *)
procedure SetConf( Conf: TSetConf ); stdcall;

begin


  WConf.TempPath := Conf.TempPath;
  WConf.Timeout  := Conf.Timeout;

  if WConf.Timeout<>0 then  
    Timeout := WConf.Timeout;

  WConf.Proxy_Use  := Conf.Proxy_Use;
  WConf.Proxy_Host := Conf.Proxy_Host;
  WConf.Proxy_Port := Conf.Proxy_Port;
  WConf.Proxy_User := Conf.Proxy_User;
  WConf.Proxy_Pass := Conf.Proxy_Pass;



end;

(* === Servers - PLUGIN PROCEDURE =========================================== *)
procedure GetServers( var DATA: TStringList ); stdcall;

var hIndex: Integer;

begin
  DATA := TStringList.Create;
  DATA.Clear;

  DATA.Add('SERVER');
  hIndex:= DATA.Count - 1;
  DATA.Objects[hIndex] := TSLServers.Create;
  TSLServers(DATA.Objects[hIndex]).ServerID   := 'wetter.com';
  TSLServers(DATA.Objects[hIndex]).ServerName := 'wetter.com';
{  TSLServers(DATA.Objects[hIndex]).ServerIcon := nil; - NOT WORK}

end;


function TransCond(sText: WideString): WideString;
var sNewText: WideString;
begin

  sNewText := sText;
  if UpperCase(sNewText) = UpperCase('k. A.') then
    sNewText := 'unknown'
  else if UpperCase(sNewText) = UpperCase('sonnig') then
    sNewText := 'Sunny'
  else if UpperCase(sNewText) = UpperCase('wolkig') then
    sNewText := 'Cloudy'
///////////////////////////////////////////////////////////////////////////////
  else if UpperCase(sNewText) = UpperCase('leicht bewölkt') then
    sNewText := 'Scattered Clouds'
  else if UpperCase(sNewText) = UpperCase('leichter Regen') then
    sNewText := 'Light Rain'
  else if UpperCase(sNewText) = UpperCase('leichter Regen - Schauer') then
    sNewText := 'Light Showers Rain'
  else if UpperCase(sNewText) = UpperCase('starker Regen - Schauer') then
    sNewText := 'Heavy Showers Rain'
  else if UpperCase(sNewText) = UpperCase('Regen - Schauer') then
    sNewText := 'Showers'
  else if UpperCase(sNewText) = UpperCase('starker Regen') then
    sNewText := 'Heavy Rain'
  else if UpperCase(sNewText) = UpperCase('mäßiger Regen') then
    sNewText := 'Light Rain'
  else if UpperCase(sNewText) = UpperCase('Gewitter') then
    sNewText := 'Thunderstorms'
  else if UpperCase(sNewText) = UpperCase('bedeckt') then
    sNewText := 'Overcast'
  else if UpperCase(sNewText) = UpperCase('Nebel') then
    sNewText := 'Fog'
  else if UpperCase(sNewText) = UpperCase('klar') then
    sNewText := 'Clear'
  else if UpperCase(sNewText) = UpperCase('Regen - Schauer') then
    sNewText := 'Showers'
  else if UpperCase(sNewText) = UpperCase('leichtes Gewitter') then
    sNewText := 'Thunderstorms'    // lehka !!!!!!!!!

  ;

  Result := sNewText;

end;


function TransDays(sText: WideString): WideString;
var sNewText: WideString;
begin

  sNewText := sText;

  if UpperCase(sNewText) = UpperCase('Montag') then
    sNewText := 'Monday'
  else if UpperCase(sNewText) = UpperCase('Dienstag') then
    sNewText := 'Tuesday'
  else if UpperCase(sNewText) = UpperCase('Mittwoch') then
    sNewText := 'Wednesday'
  else if UpperCase(sNewText) = UpperCase('Donnerstag') then
    sNewText := 'Thursday'
  else if UpperCase(sNewText) = UpperCase('Freitag') then
    sNewText := 'Friday'
  else if UpperCase(sNewText) = UpperCase('Samstag') then
    sNewText := 'Saturday'
  else if UpperCase(sNewText) = UpperCase('Sonntag') then
    sNewText := 'Sunday'
  ;

  Result := sNewText;

end;


(* === Search - PLUGIN PROCEDURE ============================================ *)
procedure Search(SearchName: WideString; Server: WideString; var DATA: TStringList; var Info: TPositionInfo ); stdcall;

var hIndex, iFS,iFS1: Integer;
    HTMLData: TResultData;
    sName,sID, sName2: WideString;
    sFound, sPlace: WideString;

Label EndProc, NextPlace;


begin
  DATA := TStringList.Create;
  DATA.Clear;

//  HTMLData := GetHTML('http://de.beta.wetter.com/suche/?search=' + SearchName, Info);
  HTMLData := GetHTML('http://de.wetter.com/suche/?search=' + SearchName,'','',10000,NO_CACHE, Info);

  if HTMLData.OK = True then
    begin
          iFS:=1;

          sFound := HTMLData.parString;

        NextPlace:
          sPlace :=  Trim(  FoundStr(sFound, '<a city_code=', '</table>',iFS,iFS) ) ;

          sName := Trim(  FoundStr(sPlace, '">', '</a>', 1, iFS1) ) ;
          sID   := Trim(  FoundStr(sPlace, '"', '"', 1, iFS1) ) ;

          sName2 := Trim(  FoundStr(sPlace, '<td class="right" style="vertical-align: top;">', '</td>', 1, iFS1) ) ;

          if sName2<>'' then
            sName := sName + ' ' + sName2;


          if sID='' then
            begin
              goto EndProc;
            end;

          DATA.Add('PLACE');
          hIndex:= DATA.Count - 1;
          DATA.Objects[hIndex] := TSLFoundPlaces.Create;
          TSLFoundPlaces(DATA.Objects[hIndex]).Name       := HTMLToText(sName);
          TSLFoundPlaces(DATA.Objects[hIndex]).ID         := HTMLToText(sID) + '@wetter.com';

          Application.ProcessMessages;

          Inc(iFS);
          GoTo NextPlace;
    end;

EndProc:


  if DATA.Count=0 then
  begin

    //  City Not Found
    DATA.Add('PLACE');
    hIndex:= DATA.Count - 1;
    DATA.Objects[hIndex] := TSLFoundPlaces.Create;
    TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
    TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';

  end;



end;


(* === Get Weather ========================================================== *)
procedure GetWeather(PlaceID: WideString; var DATA: TStringList; var Info: TPositionInfo); stdcall;

var HTMLData: TResultData;

    sPlace,sServer: WideString;

    hIndex: Integer;

    hFirstIndex: Integer;

    sItem: WideString;
    sUnit: WideString;
    sChance: WideString;

    iFS, iFS2, iFS3, ixx: Integer;
  i,r1: Integer;
    sFound, sFound2: WideString;

    F: TextFile;

    pos1, hod1: Integer;

Label acccom;
Label attt;
begin

  DATA := TStringList.Create;
  DATA.Clear;

  DecodeID(PlaceID, '@', sPlace, sServer);

  if sServer = 'wetter.com' then
  begin
    try

      //HTMLData := GetHTML('http://de.beta.wetter.com/wetter_aktuell/aktuell/?id=' + sPlace, Info);
      HTMLData := GetHTML('http://de.wetter.com/wetter_aktuell/aktuell/?id=' + sPlace,'','',10000,NO_CACHE, Info);

    except

      DATA.Add('DOWNLOAD');
      hIndex:= DATA.Count - 1;
      DATA.Objects[hIndex] := TSLFoundPlaces.Create;
      TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'ERROR';
      TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'ERROR';

      HTMLData.OK := False;

    end;

    if HTMLData.OK = True then
    begin

//      sFound := Trim(  FoundStr(HTMLData.parString, '<div class="bdins fc_rect2" style="">', '<div class="box fc_mg_top f-l" style="">',1,iFS) ) ;
      sFound := Trim(  FoundStr(HTMLData.parString, '<div class="bdins fc_rect2" style="">', '</html>',1,iFS) ) ;



      if sFound='' then
      begin
{        //  City Not Found
        DATA.Add('PLACE');
        hIndex:= DATA.Count - 1;
        DATA.Objects[hIndex] := TSLFoundPlaces.Create;
        TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
        TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';      }

      end
      else
      begin


        DATA.Add('NOW');
        hIndex:= DATA.Count - 1;
        DATA.Objects[hIndex] := TSLWeather.Create;

        //Local Time
        sItem := Trim( FoundStr(HTMLData.parString, 'Aktuelle Ortszeit:', 'hr',1,iFS) );

        sItem := NoHTML( Trim( FoundStr(sItem, ',', 'U',1,iFS) ) );


        TSLWeather(DATA.Objects[hIndex]).LocalTime := sItem;


        //       date     sItem  := Trim(  FoundStr(HTMLData.parString, '<td class="fc_middle fc_center fc_sub_title" colspan="2">', ',',1,iFS)  );
        sItem := NoHTML( Trim(  FoundStr(HTMLData.parString, '<td class="fc_middle fc_center fc_sub_title">-->', 'Uhr',1,iFS)  ) );
        TSLWeather(DATA.Objects[hIndex]).LastUpdate := sItem;


        //SUNRISE
        sItem := Trim( FoundStr(HTMLData.parString, 'sunrise.png', '<td class="fc_middle">',1,iFS ) );
        sItem := NoHTML( Trim( FoundStr(sItem, '<td class="fc_sub_title">', '</td>',1,iFS ) ) );
        TSLWeather(DATA.Objects[hIndex]).Sunrise     := sItem;

        //SUNSET
        sItem := Trim( FoundStr(HTMLData.parString, 'sunset.png', '</tr>',1,iFS ) );
        sItem := NoHTML( Trim( FoundStr(sItem, '<td class="fc_sub_title">', '</td>',1,iFS ) ) );
        TSLWeather(DATA.Objects[hIndex]).Sunset      := sItem;


        //Temperature
//        sItem := Trim( FoundStr(HTMLData.parString, '<td class="fc_temper fc_center">', '</td>',1,iFS)  );
//        sItem := Trim( FoundStr(sItem, '<span class="temp">', '</span>',1,iFS)  );
        sItem := Trim( FoundStr(HTMLData.parString, '<td class="fc_temper fc_center">', '</td>',1,iFS)  );
        sItem := NoHTML( Trim( FoundStr(sItem, '<span class="temp_observe">', '</span>',1,iFS)  ) );
        sUnit := 'C';
        TSLWeather(DATA.Objects[hIndex]).Temperature.Value     := sItem;
        TSLWeather(DATA.Objects[hIndex]).Temperature.ValueUnit := sUnit;

        // Condition
        sItem := NoHTML( Trim( FoundStr(HTMLData.parString, '<td class="fc_sub_title fc_center">', '</td>',1,iFS )  ) );
        TSLWeather(DATA.Objects[hIndex]).Condition := TransCond(HTMLToText(sItem));

        //Humidity
        sItem := NoHTML( Trim( FoundLastChar( FoundStr(HTMLData.parString, 'relative Feuchte', '%',1,iFS ) ) ) );
//        if Copy(sItem,1,6) = '<table' then
        if sItem = '' then
          TSLWeather(DATA.Objects[hIndex]).Humidity := ''
        else
          TSLWeather(DATA.Objects[hIndex]).Humidity := sItem+'%';

{
              // Wind Direction
              sItem := Trim( FoundStr(HTMLData.parString, 'Winds: ', '<br/>',1,iFS ) );
              TSLWeather(DATA.Objects[hIndex]).WindDirection := sItem;
}

        // WindSpeed
        sItem := NoHTML( Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Windgeschwindigkeit', 'km/h',iFS,iFS ) ) ) );
        sUnit := 'km/h';
        TSLWeather(DATA.Objects[hIndex]).WindSpeed.Value     := sItem;
        TSLWeather(DATA.Objects[hIndex]).WindSpeed.ValueUnit := sUnit;


        //Visibility
        sItem := NoHTML( Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Sicht', 'km',iFS,iFS ) ) ) );
        sUnit := 'km';
        TSLWeather(DATA.Objects[hIndex]).Visibility.Value     := sItem;
        TSLWeather(DATA.Objects[hIndex]).Visibility.ValueUnit := sUnit;


        //Pressure
        sItem := NoHTML( Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Luftdruck', 'hPa',iFS,iFS ) ) ) );
        sUnit := 'hPa';
        TSLWeather(DATA.Objects[hIndex]).Pressure.Value     := sItem;
        TSLWeather(DATA.Objects[hIndex]).Pressure.ValueUnit := sUnit;

        {


        //Dew Point
        sItem := Trim( FoundStr(HTMLData.parString, 'Dew Point: ', '&deg; C',iFS,iFS ) ) ;
        sUnit := 'C';
        TSLWeather(DATA.Objects[hIndex]).DewPoint.Value     := sItem;
        TSLWeather(DATA.Objects[hIndex]).DewPoint.ValueUnit := sUnit;
        }

      end;

    end;

    try

      //HTMLData := GetHTML('http://de.beta.wetter.com/wetter_aktuell/wettervorhersage/16_tagesvorhersage/?id=' + sPlace, Info);
      HTMLData := GetHTML('http://de.wetter.com/wetter_aktuell/wettervorhersage/16_tagesvorhersage/?id=' + sPlace,'','',10000,NO_CACHE, Info);

    except

      DATA.Add('DOWNLOAD');
      hIndex:= DATA.Count - 1;
      DATA.Objects[hIndex] := TSLFoundPlaces.Create;
      TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'ERROR';
      TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'ERROR';

      HTMLData.OK := False;

    end;

    if HTMLData.OK = True then
    begin
      sFound := Trim(  FoundStr(HTMLData.parString, '<div class="clearing">', '<div id="fc_navigation_2" class="box">',1,iFS) );

      iFS:=1;
      for i:= 1 to 16 do
      begin

        if i=1 then
        begin
          DATA.Add('TODAY');
          hIndex:= DATA.Count - 1;
          DATA.Objects[hIndex] := TSLNextDayWeather.Create;
          TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + (i - 1) );
        end
        else
        begin
          DATA.Add('FORECAST');
          hIndex:= DATA.Count - 1;
          DATA.Objects[hIndex] := TSLNextDayWeather.Create;
          TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + (i - 1) );
        end;

        iFS := StrPosE(sFound,'<table class="fc_content">',iFS+1,False);
        sFound2 := Trim(  FoundStr(sFound, '<table class="fc_content">', '</table>',iFS,iFS2) );

        iFS3 := 0;

        //Day
        iFS3 := StrPosE(sFound2,'<tr>',iFS3 + 1,False);
        sItem := Trim(  FoundStr(sFound2, '<td class="fc_title fc_center">', ',',iFS3,iFS2) );
        hIndex:= DATA.Count - 1;
        TSLNextDayWeather(DATA.Objects[hIndex]).Day := TransDays(sItem);

        //Date  - > NO <
        iFS3 := StrPosE(sFound2,'<tr>',iFS3 + 1,False);

        //Cond. image - > NO <
        iFS3 := StrPosE(sFound2,'<tr>',iFS3 + 1,False);

        //Condition
        iFS3 := StrPosE(sFound2,'<tr>',iFS3 + 1,False);
        sItem  := Trim(  FoundStr(sFound2, '<td class="fc_sub_title fc_center">', '</td>',iFS3,iFS2) );
        hIndex:= DATA.Count - 1;
        TSLNextDayWeather(DATA.Objects[hIndex]).Condition := TransCond(HTMLToText(sItem));

        //Temperature
        iFS3 := StrPosE(sFound2,'<tr>',iFS3 + 1,False);

        //  Temp. High
        sItem := Trim(  FoundStr(sFound2, '/ <span class="temp">', '</span>',iFS3,iFS2) ) ;
        sUnit := 'C';
        hIndex:= DATA.Count - 1;
        TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
        TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;

        //  Temp. Low
        sItem := Trim(  FoundStr(sFound2, '><span class="temp">', '</span>',iFS3,iFS2) ) ;
        sUnit := 'C';
        hIndex:= DATA.Count - 1;
        TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value     := sItem;
        TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;


        Application.ProcessMessages;
      end;

    end;

  end; //if wetter.com

end;



exports GetPluginInfo;
exports GetServers;
exports SetConf;
exports GetWeather;
exports Search;


end.
