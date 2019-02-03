unit W_plugin;

interface

uses SysUtils, Classes, Dialogs, Graphics, Windows, Forms, W_plugin_info,
     WinInet, mshtml, SHDocVw, ExtCtrls, TextSearch, DownloadFile, Convs;


const
  W_PLUGIN_VER_MAJOR = 0;
  W_PLUGIN_VER_MINOR = 10;
  W_PLUGIN_NAME      : WideString = 'wunderground.com';
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
  TSLServers(DATA.Objects[hIndex]).ServerID   := 'wunderground.com';
  TSLServers(DATA.Objects[hIndex]).ServerName := 'wunderground.com';
{  TSLServers(DATA.Objects[hIndex]).ServerIcon := nil; - NOT WORK}


end;

(* === Search - PLUGIN PROCEDURE ============================================ *)
procedure Search(SearchName: WideString; Server: WideString; var DATA: TStringList; var Info: TPositionInfo ); stdcall;

var hIndex, iFS: Integer;
    HTMLData: TResultData;
    sName,sID: WideString;




Label EndProc;
Label NextPlace;
begin
  DATA := TStringList.Create;
  DATA.Clear;




  HTMLData := GetHTML('http://english.wunderground.com/cgi-bin/findweather/getForecast?query=' + SearchName, '', '', 10000, NO_CACHE, Info);

  if HTMLData.OK = True then
    begin
      //  City Not Found

      iFS := StrPosE(HTMLData.parString, 'City Not Found',1,False);
      if iFS<>0 then
        begin
          DATA.Add('PLACE');
          hIndex:= DATA.Count - 1;
          DATA.Objects[hIndex] := TSLFoundPlaces.Create;
          TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
          TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';
        end

      else
        begin
          sName := Trim(  FoundStr(HTMLData.parString, 'type="application/rss+xml" title="', ' RSS"',1,iFS) ) ;
          sID   := Trim(  FoundStr(HTMLData.parString, 'global/stations/', '.xml"',1,iFS) ) ;

//          showmessage(sName+#13+sID);

          if sID='' then
            begin
              iFS:=1;
        NextPlace:
              sID   := Trim(  FoundStr(HTMLData.parString, 'global/stations/', '.html">',iFS,iFS) ) ;
              sName := Trim(  FoundStr(HTMLData.parString, '">', '</a>',iFS,iFS) ) ;

              if sID='' then
                begin
                  goto EndProc;
                end;

              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := sName;
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := sID + '@wunderground.com';
Application.ProcessMessages;
              GoTo NextPlace;

//              Trim(  FoundStr(HTMLData.parString, 'global/stations/', '.xml">',iFS,iFS) ) ;

//		<td class="sortC"><a href="/global/stations/11541.html">Ceske Budejovice</a>
//                <td class="sortC"><a href="/global/stations/
            end
          else
            begin


              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := sName;
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := sID + '@wunderground.com';
            end;
        end;
    end;

EndProc:

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

    iFS, ixx: Integer;
  i: Integer;
    sDay,sCond, sHigh, sHighU, sLow, sLowU: WideString;

      Pos1, Hod1: Integer;

Label TL;
begin

  DATA := TStringList.Create;
  DATA.Clear;

  DecodeID(PlaceID, '@', sPlace, sServer);

  if sServer = 'wunderground.com' then
    begin

      try     
        HTMLData := GetHTML('http://english.wunderground.com/global/stations/' + sPlace + '.html', '','',10000,NO_CACHE, Info);
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
//          City Not Found

          iFS := StrPosE(HTMLData.parString, 'City Not Found',1,False);
          if iFS<>0 then
            begin
              sItem := 'NOT FOUND';
              sUnit := '';
              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLWeather.Create;
              TSLWeather(DATA.Objects[hIndex]).LocalTime := sItem;
              TSLWeather(DATA.Objects[hIndex]).LastUpdate := sUnit;
            end
          else
            begin
              DATA.Add('NOW');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLWeather.Create;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Local Time:', '</span>',1,iFS) ) );

              Pos1 := StrPosE(sItem, 'CET',1,False);
              Pos1 := Pos1 - 1;
              sItem := Trim(Copy(sItem,1,Pos1));

              
              if Copy(sItem,Length(sItem) - 1,2)='AM' then
                sItem := Trim(Copy(sItem,1,Length(sItem) - 2))
              else if Copy(sItem,Length(sItem) - 1,2)='PM' then
              begin

                sItem := Trim(Copy(sItem,1,Length(sItem) - 2));

                Pos1 := StrPosE(sItem,':',1,False);
                hod1 := StrToInt(Copy(sItem,1,Pos1-1) );

                if hod1=12 then
                  sItem :=  IntToStr(hod1) + Copy(sItem,Pos1)
                else
                  sItem := IntToStr( hod1 + 12) + Copy(sItem,Pos1);

              end;

              TSLWeather(DATA.Objects[hIndex]).LocalTime := sItem;

(*
              sItem := FoundLastChar(  FoundStr(HTMLData.parString, 'Active Advisory:</span>', '</a></NOBR>') );
              sUnit := '';
              DATA.Add('ALERT');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLWeather.Create;
              TSLWeather(DATA.Objects[hIndex]).I1 := sItem;
              TSLWeather(DATA.Objects[hIndex]).I2 := '';
*)


              sItem := Trim( FoundLastChar( FoundLastChar(   FoundStr(HTMLData.parString, 'Updated:', '</span>',1,iFS) ) ) );
              TSLWeather(DATA.Objects[hIndex]).LastUpdate := sItem;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<div style="font-size: 17px;">', '</span>&nbsp;&#176;F</span>',1,iFS)  ) );
//              showmessage(sItem);
              sUnit := 'F';
              TSLWeather(DATA.Objects[hIndex]).Temperature.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Temperature.ValueUnit := sUnit;


              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<div class="b" style="font-size: 14px;">', '</div>',1,iFS ) ) );
              TSLWeather(DATA.Objects[hIndex]).Condition := sItem;

              sItem := Trim( FoundStr(
                         FoundStr(HTMLData.parString, 'Humidity:</td>', '</td>',1,iFS )
                                 , '<nobr>', '</nobr>',1,iFS ) );
              TSLWeather(DATA.Objects[hIndex]).Humidity := sItem;

              sItem := Trim( FoundLastChar(    FoundStr(HTMLData.parString, 'Dew Point:</td>', '</b>&nbsp;&deg;F</nobr>',1,iFS ) ) );
              sUnit := 'F';
              TSLWeather(DATA.Objects[hIndex]).DewPoint.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).DewPoint.ValueUnit := sUnit;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'pwsvariable="windspeedmph" english="mph" metric="km/h">', '</b>&nbsp;mph</nobr>',1,iFS ) ) );
              sUnit := 'mph';
              TSLWeather(DATA.Objects[hIndex]).WindSpeed.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).WindSpeed.ValueUnit := sUnit;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'pwsvariable="winddir"', '</span>',1,iFS ) ) );
              TSLWeather(DATA.Objects[hIndex]).WindDirection := sItem;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Pressure:</td>', '</b>',1,iFS ) ) );
              sUnit := 'in';
              TSLWeather(DATA.Objects[hIndex]).Pressure.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Pressure.ValueUnit := sUnit;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Pressure:</td>', '</td>',1,iFS ) ) );
              if Copy(sItem,1,1)='(' then
                begin
                  if Copy(sItem,Length(sItem),1)=')' then
                    begin
                      sItem := Copy(sItem,2, Length(sItem)-2);
                    end;
                end;
              TSLWeather(DATA.Objects[hIndex]).PressureChange :=sItem;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Visibility:</td>', '</b>&nbsp;miles</nobr>',1,iFS ) ) );
              sUnit := 'miles';
              TSLWeather(DATA.Objects[hIndex]).Visibility.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Visibility.ValueUnit := sUnit;

              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'UV:</td>', '<span style="font-weight: normal;">',1,iFS ) ) );
              TSLWeather(DATA.Objects[hIndex]).UV := sItem;

              // SUNRISE
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Actual Time</td>', '</td>',1,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).SUNRISE := sItem;

              //SUNSET
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<td style="border-bottom: 1px solid #CCC;">', '</td>',iFS,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).SUNSET := sItem;

              //MOONRISE
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Moon</td>', '</td>',1,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).MOONRISE := sItem;

              //MOONSET
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<td style="border-bottom: 1px solid #CCC;">', '</td>',iFS,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).MOONSET := sItem;

              //VISIBLE LIGHT LENGTH
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Length Of Visible Light:</td>', '</b></td>',1,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).VISIBLE LIGHT LENGTH := sItem;

              //DAY LENGTH
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Length of Day</td>', '</div>',1,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).DAY LENGTH := sItem;

              //HLEDA DALE podle posledni pozice
              //MOON PHASE
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<td colspan="5">', '</h4>',iFS,iFS ) ) );
//              TSLWeather(DATA.Objects[hIndex]).MOON PHASE := sItem;

              iFS := StrPosE(HTMLData.parString, '<table class="boxB" id="full" cellspacing="0" cellpadding="0" style="margin-bottom: 10px;">',1,False);


              DATA.Add('TODAY');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;
              hFirstIndex := hIndex;
              TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now );

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;
              TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + 1 );

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;
              TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + 2 );

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;
              TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + 3 );

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;
              TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + 4 );

              for i:= 1 to 5 do
                begin
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<td class="taC" style="width: 20%;">', '</td>', iFS, iFS ) ) );
                  hIndex := hFirstIndex + (i - 1);
                  TSLNextDayWeather(DATA.Objects[hIndex]).Day := sItem;

                  Application.ProcessMessages;
                end;

              for i:= 1 to 5 do
                begin
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<span style="color: #900;">', '&deg;', iFS, iFS ) ) );
                  sUnit := 'F';

                  hIndex := hFirstIndex + (i - 1);
                  TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
                  TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;


                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<span style="color: #009;">', '&deg;', iFS, iFS ) ) );
                  sUnit := 'F';
                  TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value := sItem;
                  TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;


                  //Preskoci celsia
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<span style="color: #900;">', '&deg;', iFS, iFS ) ) );
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<span style="color: #009;">', '&deg;', iFS, iFS ) ) );

                  Application.ProcessMessages;
                end;


              for i:= 1 to 5 do
                begin
                  sItem   := '';
                  sChance := '';

                  sItem := Trim(  FoundStr(HTMLData.parString, '<td class="taC" >', '</td>', iFS - 2, iFS )  );

                  sChance := Trim(  FoundStr(sItem, 'class="b green">', '</span>', 1, ixx )  );

                  sItem := Trim( FoundFirstChar( sItem ) );


                  hIndex := hFirstIndex + (i - 1);
                  TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;

                  TSLNextDayWeather(DATA.Objects[hIndex]).ChanceOfPrec := sChance;


                  Application.ProcessMessages;
                end;

              iFS := StrPosE(HTMLData.parString, '<td class="full">Extended Forecast</td>', 1 , False );
//showmessage( INTTOSTR(iFS) );

              for i:= 1 to 7 do
                begin

                  sDay   := Trim(  FoundStr(HTMLData.parString, '<div class="b">', '</div>', iFS, iFS ) );

                  sCond  := Trim( FoundLastChar( FoundStr(HTMLData.parString, '</div>', '.', iFS - 20, iFS ) ) );

                  sHigh  := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'High:', '&deg; F.', iFS, iFS ) ) );
                  sHighU := 'F';

                  sLow   := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Low:', '&deg; F.', iFS, iFS ) ) );
                  sLowU  := 'F';

{                  if i=6 then
                    begin
                      Goto TL;
                    end
                  else }if i=6 then
                    begin

                     TL:
                      DATA.Add('FORECAST');
                      hIndex:= DATA.Count - 1;
                      DATA.Objects[hIndex] := TSLNextDayWeather.Create;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Date :=  FormatDateTime('yyyy-mm-dd' , Now + 5 );                      
                      TSLNextDayWeather(DATA.Objects[hIndex]).Day                       := sDay;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Condition                 := sCond;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value     := sHigh;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sHighU;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value      := sLow;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit  := sLowU;
                    end;

                end;


(*

              for i:= 1 to 7 do
                begin
                  //day TEXT
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '</b><br>', '</td></tr>', iFS, iFS ) ) );

                  if i=6 then
                    begin
                      DATA.Add('FORECAST');
                      hIndex:= DATA.Count - 1;
                      DATA.Objects[hIndex] := TSLNextDayWeather.Create;

                      sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'High:', '&deg; F.', iFS, iFS ) ) );
                      sUnit := 'F';

                      hIndex := hFirstIndex + (i - 1);
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;

                    end
                  else if i=7 then
                    begin
                      DATA.Add('FORECAST');
                      hIndex:= DATA.Count - 1;
                      DATA.Objects[hIndex] := TSLNextDayWeather.Create;

                      sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'High:', '&deg; F.', iFS, iFS ) ) );
                      sUnit := 'F';

                      hIndex := hFirstIndex + (i - 1);
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;

                    end;


                  //NIGHT TEXT
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Night</b><br>', '</td></tr>', iFS, iFS ) ) );


                  if i=6 then
                    begin
                      sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Low:', '&deg; F.', iFS, iFS ) ) );
                      sUnit := 'F';
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;


                    end
                  else if i=7 then
                    begin
                      sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Low:', '&deg; F.', iFS, iFS ) ) );
                      sUnit := 'F';
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;
                    end;

                  Application.ProcessMessages;
                  
                end;

*)

            end;


        end;


    end;

end;



exports GetPluginInfo;
exports GetServers;
exports SetConf;
exports GetWeather;
exports Search;


end.
