unit W_plugin;

interface

uses SysUtils, Classes, Dialogs, Graphics, Windows, Forms, W_plugin_info,
     WinInet, mshtml, SHDocVw, ExtCtrls, TextSearch, DownloadFile, Convs;


const
  W_PLUGIN_VER_MAJOR = 0;
  W_PLUGIN_VER_MINOR = 10;
  W_PLUGIN_NAME      : WideString = 'accuweather.com';
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
  TSLServers(DATA.Objects[hIndex]).ServerID   := 'accuweather.com';
  TSLServers(DATA.Objects[hIndex]).ServerName := 'accuweather.com';
{  TSLServers(DATA.Objects[hIndex]).ServerIcon := nil; - NOT WORK}

  DATA.Add('SERVER');
  hIndex:= DATA.Count - 1;
  DATA.Objects[hIndex] := TSLServers.Create;
  TSLServers(DATA.Objects[hIndex]).ServerID   := 'accuweather-us.com';
  TSLServers(DATA.Objects[hIndex]).ServerName := 'accuweather-us.com';
{  TSLServers(DATA.Objects[hIndex]).ServerIcon := nil; - NOT WORK}

end;

(* === Search - PLUGIN PROCEDURE ============================================ *)
procedure Search(SearchName: WideString; Server: WideString; var DATA: TStringList; var Info: TPositionInfo ); stdcall;

var hIndex, iFS,iFS1: Integer;
    HTMLData: TResultData;
    sName,sID: WideString;
    sFound, sPlace: WideString;

Label EndProc, NextPlace;
Label EndProcUS, NextPlaceUS;

begin
  DATA := TStringList.Create;
  DATA.Clear;

  HTMLData := GetHTML('http://www.accuweather.com/world-city-list.asp?locCode=' + SearchName, '', '', 10000, NO_CACHE, Info);

  if HTMLData.OK = True then
    begin

      sFound := Trim(  FoundStr(HTMLData.parString, '<div class="textmedblue">', '</ul>',1,iFS) ) ;

      if sFound='' then
        begin
          sFound := Trim(  FoundStr(HTMLData.parString, '<div id="fcst_heading">', '</a>',1,iFS) ) ;

          if sFound='' then
            begin
              //  City Not Found
              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';
            end
          else
            begin
              sName := Trim( FoundLastChar( sFound) ) ;
              sID   := Trim(  FoundStr(sFound, 'locCode=', '&amp;',1,iFS) ) ;

              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := sName;
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := sID + '@accuweather.com';
            end;

        end
      else
        begin
          iFS:=1;
        NextPlace:
          sPlace :=  Trim(  FoundStr(sFound, '<li>', '</li>',iFS,iFS) ) ;

          sName := Trim(  FoundStr(sPlace, '">', '</a>', 1, iFS1) ) ;
          sID   := Trim(  FoundStr(sPlace, 'loccode=', '">', 1, iFS1) ) ;


          if sID='' then
            begin
              goto EndProc;
            end;

          DATA.Add('PLACE');
          hIndex:= DATA.Count - 1;
          DATA.Objects[hIndex] := TSLFoundPlaces.Create;
          TSLFoundPlaces(DATA.Objects[hIndex]).Name       := sName;
          TSLFoundPlaces(DATA.Objects[hIndex]).ID         := sID + '@accuweather.com';

          Application.ProcessMessages;
          GoTo NextPlace;



        end;
    end;

EndProc:

  HTMLData := GetHTML('http://www.accuweather.com/us-city-list.asp?zipcode=' + SearchName, '', '', 10000, NO_CACHE, Info);

  if HTMLData.OK = True then
    begin
      sFound := Trim(  FoundStr(HTMLData.parString, '<div style="margin-left:5px;line-height:15px;" class="textmsmall">', '</div>',1,iFS) ) ;

      if sFound='' then
        begin
          sPlace :=  Trim(  FoundStr(HTMLData.parString, '<div class="city_heading">', '</div>',1,iFS) ) ;



          if sPlace<>'' then
            begin

              sName := Trim( FoundLastChar( FoundStr(sPlace, 'class="city_heading"', '</a>', 1, iFS1) ) ) ;
              sID   := Trim( FoundStr(sPlace, 'zipcode=', '&', 1, iFS1) );


              if sID='' then
                begin
                  goto EndProcUS;
                end;

              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := sName;
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := sID + '@accuweather-us.com';
                            
            end
          else
            begin

              //  City Not Found
              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';

            end;
        end

      else
        begin

              iFS:=1;
            NextPlaceUS:
              sPlace :=  Trim(  FoundStr(sFound, '<a href="http://www.accuweather.com/us', '</a><br/>',iFS,iFS) ) ;

              sName := FoundLastChar( sPlace ); //Trim(  FoundStr(sPlace, '">', '</a>', 1, iFS1) ) ;
              sID   := Trim( FoundLastChar( FoundStr(sPlace, '/', '/city-weather-forecast.asp', 1, iFS1), '/' ) ) ;


              if sID='' then
                begin
                  goto EndProcUS;
                end;

              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := sName;
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := sID + '@accuweather-us.com';

              Application.ProcessMessages;
              GoTo NextPlaceUS;


        end;

    end;

EndProcUS:

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

    iFS, iFS2, ixx: Integer;
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
  if sServer = 'accuweather-us.com' then
    begin

      try

        HTMLData := GetHTML('http://www.accuweather.com/index-forecast.asp?zipcode=' + sPlace + '&metric=1','','',10000,NO_CACHE, Info);

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
(*      AssignFile(F, 'C:\_\' + sPlace + '.txt');
      Rewrite(F);
      writeln(f,HTMLData.parString);
      CloseFile(F);  *)

(*


          sFound := Trim(  FoundStr(HTMLData.parString, '<div id="fcst_heading">', '</a>',1,iFS) ) ;

          if sFound='' then
            begin
              //  City Not Found
              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';


            end
          else
            begin


*)


//Currently At

              DATA.Add('NOW');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLWeather.Create;

              //Local Time
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Currently</span> At ', '</div>',1,iFS) ) );

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


{
              sItem := Trim( FoundLastChar( FoundLastChar(   FoundStr(HTMLData.parString, 'Updated:</span>', '</span>',1,iFS) ) ) );
              TSLWeather(DATA.Objects[hIndex]).LastUpdate := sItem;
}
              //Temperature
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'current_temps">', '&deg;C</div>',1,iFS)  ) );
              sUnit := 'C';
{              showmessage('START' + sItem);
              if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;C' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'C';
                end
              else if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;F' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'F';
                end
              else
                begin     //spatna jednotka
                  sItem := '';
                  sUnit := '';
                end;  }
              TSLWeather(DATA.Objects[hIndex]).Temperature.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Temperature.ValueUnit := sUnit;
{              showmessage('end' + sItem);}


{             CO TO JE????
              //Temperature - RealFeel®
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'current_rfval">', '</div>',1,iFS)  ) );
              if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;C' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'C';
                end
              else if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;F' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'F';
                end
              else
                begin     //spatna jednotka
                  sItem := '';
                  sUnit := '';
                end;
              TSLWeather(DATA.Objects[hIndex]).Temperature???.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Temperature???.ValueUnit := sUnit;
}
              // Wind Direction
              sItem := Trim( FoundStr(HTMLData.parString, 'Winds: ', '<br/>',1,iFS ) );
              TSLWeather(DATA.Objects[hIndex]).WindDirection := sItem;

              // WindSpeed
              sItem := Trim( FoundStr(HTMLData.parString, 'at ', 'km/h</div>',iFS,iFS )  );
              sUnit := 'km/h';
              TSLWeather(DATA.Objects[hIndex]).WindSpeed.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).WindSpeed.ValueUnit := sUnit;

              // Condition
              sItem := Trim( FoundStr(HTMLData.parString, 'quicklook_current_wxtext">', '</div>',1,iFS )  );
              TSLWeather(DATA.Objects[hIndex]).Condition := sItem;

              //Humidity
              sItem := Trim( FoundStr(HTMLData.parString, 'Humidity: ', '<br />',1,iFS )  );
              TSLWeather(DATA.Objects[hIndex]).Humidity := sItem;

              //Dew Point
              sItem := Trim( FoundStr(HTMLData.parString, 'Dew Point: ', '&deg; C',iFS,iFS ) ) ;
              sUnit := 'C';
              TSLWeather(DATA.Objects[hIndex]).DewPoint.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).DewPoint.ValueUnit := sUnit;

              //Pressure
              sItem := Trim( FoundStr(HTMLData.parString, 'Pressure: ', ' KPA</div>',iFS,iFS ) ) ;
              sUnit := 'kPa';
              TSLWeather(DATA.Objects[hIndex]).Pressure.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Pressure.ValueUnit := sUnit;

              //Visibility
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, #9+'Visibility: ', '&nbsp;km',1,iFS ) ) );
              sUnit := 'km';
              TSLWeather(DATA.Objects[hIndex]).Visibility.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Visibility.ValueUnit := sUnit;


              //SUNRISE
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Sunrise</a>: ', '</div>',1,iFS ) ) );

              if Copy(sItem,Length(sItem) - 1,2)='AM' then
                sItem := Trim(Copy(sItem,1,Length(sItem) - 2))
              else if Copy(sItem,Length(sItem) - 1,2)='PM' then
              begin

                sItem := Trim(Copy(sItem,1,Length(sItem) - 2));

                Pos1 := StrPosE(sItem,':',1,False);

                sItem := IntToStr(StrToInt(Copy(sItem,1,Pos1-1)) + 12) + Copy(sItem,Pos1);

              end;

              TSLWeather(DATA.Objects[hIndex]).Sunrise     := sItem;


              //SUNSET
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Sunset</a>: ', '</div>',1,iFS ) ) );

              if Copy(sItem,Length(sItem) - 1,2)='AM' then
                sItem := Trim(Copy(sItem,1,Length(sItem) - 2))
              else if Copy(sItem,Length(sItem) - 1,2)='PM' then
              begin

                sItem := Trim(Copy(sItem,1,Length(sItem) - 2));

                Pos1 := StrPosE(sItem,':',1,False);

                sItem := IntToStr(StrToInt(Copy(sItem,1,Pos1-1)) + 12) + Copy(sItem,Pos1);

              end;

              TSLWeather(DATA.Objects[hIndex]).Sunset      := sItem;



              HTMLData := GetHTML('http://www.accuweather.com/forecast-15day.asp?zipcode=' + sPlace + '&metric=1','','',10000,NO_CACHE, Info);
              if HTMLData.OK = True then
                begin
                  sFound := Trim(  FoundStr(HTMLData.parString, '<div class="content_box_435body" id="content_box_435_all15day">', '<div class="content_box_435bluenavbar">',1,iFS) );

//                  showmessage(sFound);

                  iFS:=1;
                  for i:= 1 to 15 do
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
{
                      sFound2 := Trim(  FoundStr(sFound, '<div class="forecastHeaderLeft">', '<div class="forecastHeaderLeft">',iFS,iFS) );
                      iFS:= iFS - Length('<div class="forecastHeaderLeft">') - 2;

                      showmessage(sFound2);
}
                      iFS := StrPosE(sFound,'<div class="forecastHeaderLeft">',iFS,False) + 1;

//                      showmessage(INTTOSTR(iFS));


                      //Day
                      sItem := Trim(  FoundStr(sFound, 'class="detailLink">', '</a>',iFS,iFS2) );
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Day := sItem;

{
                      //  Condition
                      sItem := Trim(  FoundStr(sFound, 'class="fcstSmTextBox">', '</div>',iFS,iFS2) ) ;
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;
}
                      //  Condition
                      sItem := Trim(  FoundStr(sFound, 'alt="', '"',iFS,iFS2) ) ;
                      sItem := HTMLToText(sItem);
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;




                      //  Temp. High
                      sItem := Trim(  FoundStr(sFound, 'High:', '&deg;C</div>',iFS,iFS2) ) ;
                      sUnit := 'C';
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;

                      //  Temp. Low
                      sItem := Trim(  FoundStr(sFound, 'Low:', '&deg;C</div>',iFS,iFS2) ) ;
                      sUnit := 'C';
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value     := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;

                      Application.ProcessMessages;
                    end;


                end;




(*            end;*)


        end;



    end

  else if sServer = 'accuweather.com' then
    begin

      try

        HTMLData := GetHTML('http://www.accuweather.com/world-index-forecast.asp?locCode=' + sPlace + '&metric=1','','',10000,NO_CACHE, Info);

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

          sFound := Trim(  FoundStr(HTMLData.parString, '<div id="fcst_heading">', '</a>',1,iFS) ) ;

          if sFound='' then
            begin
              //  City Not Found
              DATA.Add('PLACE');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLFoundPlaces.Create;
              TSLFoundPlaces(DATA.Objects[hIndex]).Name       := 'NOT FOUND';
              TSLFoundPlaces(DATA.Objects[hIndex]).ID         := 'NOT FOUND';


            end
          else
            begin

//Currently At

              DATA.Add('NOW');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLWeather.Create;

              //Local Time
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Currently At', '</a>',1,iFS) ) );


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


{
              sItem := Trim( FoundLastChar( FoundLastChar(   FoundStr(HTMLData.parString, 'Updated:</span>', '</span>',1,iFS) ) ) );
              TSLWeather(DATA.Objects[hIndex]).LastUpdate := sItem;
}
              //Temperature
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'current_temps">', '&deg;C</div>',1,iFS)  ) );
              sUnit := 'C';
{              showmessage('START' + sItem);
              if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;C' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'C';
                end
              else if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;F' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'F';
                end
              else
                begin     //spatna jednotka
                  sItem := '';
                  sUnit := '';
                end;  }
              TSLWeather(DATA.Objects[hIndex]).Temperature.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Temperature.ValueUnit := sUnit;
{              showmessage('end' + sItem);}


{             CO TO JE????
              //Temperature - RealFeel®
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'current_rfval">', '</div>',1,iFS)  ) );
              if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;C' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'C';
                end
              else if Copy(sItem, Length(sItem) - 6, 6) =  '&deg;F' then
                begin
                  sItem := Copy(sItem, 1, Length(sItem) - 6);
                  sUnit := 'F';
                end
              else
                begin     //spatna jednotka
                  sItem := '';
                  sUnit := '';
                end;
              TSLWeather(DATA.Objects[hIndex]).Temperature???.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Temperature???.ValueUnit := sUnit;
}
              // Wind Direction
              sItem := Trim( FoundStr(HTMLData.parString, 'Winds: ', '<br/>',1,iFS ) );
              TSLWeather(DATA.Objects[hIndex]).WindDirection := sItem;

              // WindSpeed
              sItem := Trim( FoundStr(HTMLData.parString, 'at ', 'km/h</div>',iFS,iFS )  );
              sUnit := 'km/h';
              TSLWeather(DATA.Objects[hIndex]).WindSpeed.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).WindSpeed.ValueUnit := sUnit;

              // Condition
              sItem := Trim( FoundStr(HTMLData.parString, 'quicklook_current_wxtext">', '</div>',1,iFS )  );
              TSLWeather(DATA.Objects[hIndex]).Condition := sItem;

              //Humidity
              sItem := Trim( FoundStr(HTMLData.parString, 'Humidity: ', '<br />',1,iFS )  );
              TSLWeather(DATA.Objects[hIndex]).Humidity := sItem;

              //Dew Point
              sItem := Trim( FoundStr(HTMLData.parString, 'Dew Point: ', '&deg; C',iFS,iFS ) ) ;
              sUnit := 'C';
              TSLWeather(DATA.Objects[hIndex]).DewPoint.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).DewPoint.ValueUnit := sUnit;

              //Pressure
              sItem := Trim( FoundStr(HTMLData.parString, 'Pressure: ', ' KPA</div>',iFS,iFS ) ) ;
              sUnit := 'kPa';
              TSLWeather(DATA.Objects[hIndex]).Pressure.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Pressure.ValueUnit := sUnit;

              //Visibility
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Visibility: ', '&nbsp;km',1,iFS ) ) );
              sUnit := 'km';
              TSLWeather(DATA.Objects[hIndex]).Visibility.Value     := sItem;
              TSLWeather(DATA.Objects[hIndex]).Visibility.ValueUnit := sUnit;

              //SUNRISE
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Sunrise</a>: ', '</div>',1,iFS ) ) );

              if Copy(sItem,Length(sItem) - 1,2)='AM' then
                sItem := Trim(Copy(sItem,1,Length(sItem) - 2))
              else if Copy(sItem,Length(sItem) - 1,2)='PM' then
              begin

                sItem := Trim(Copy(sItem,1,Length(sItem) - 2));

                Pos1 := StrPosE(sItem,':',1,False);

                sItem := IntToStr(StrToInt(Copy(sItem,1,Pos1-1)) + 12) + Copy(sItem,Pos1);

              end;

              TSLWeather(DATA.Objects[hIndex]).Sunrise     := sItem;


              //SUNSET
              sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Sunset</a>: ', '</div>',1,iFS ) ) );

              if Copy(sItem,Length(sItem) - 1,2)='AM' then
                sItem := Trim(Copy(sItem,1,Length(sItem) - 2))
              else if Copy(sItem,Length(sItem) - 1,2)='PM' then
              begin

                sItem := Trim(Copy(sItem,1,Length(sItem) - 2));

                Pos1 := StrPosE(sItem,':',1,False);

                sItem := IntToStr(StrToInt(Copy(sItem,1,Pos1-1)) + 12) + Copy(sItem,Pos1);

              end;

              TSLWeather(DATA.Objects[hIndex]).Sunset      := sItem;

//              showmessage(TSLWeather(DATA.Objects[hIndex]).LocalTime+#13+TSLWeather(DATA.Objects[hIndex]).Sunrise + #13 + TSLWeather(DATA.Objects[hIndex]).Sunset);

                            
(*


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


              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;
              hFirstIndex := hIndex;

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;

              DATA.Add('FORECAST');
              hIndex:= DATA.Count - 1;
              DATA.Objects[hIndex] := TSLNextDayWeather.Create;

              for i:= 1 to 5 do
                begin
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '<td style="width: 20%;">', '</h4>', iFS, iFS ) ) );
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
                  sItem := Trim(  FoundStr(HTMLData.parString, '<td style="border-left: 1px solid #DDD; border-right: 1px solid #DDD; padding: 2px;">', '</td>', iFS - 2, iFS )  );

                  sChance := Trim(  FoundStr(sItem, '">', '</', 1, ixx )  );


                  sItem := Trim( FoundFirstChar( sItem ) );

                  hIndex := hFirstIndex + (i - 1);
                  TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;

                  TSLNextDayWeather(DATA.Objects[hIndex]).ChanceOfPrec := sChance;


                  Application.ProcessMessages;
                end;

{
              for i:= 1 to 5 do
                begin
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, '</b><br>', '</td></tr>', iFS, iFS ) ) );

                  //TEXT
                  hIndex := hFirstIndex + (i - 1);
                  TSLNextDayWeather(DATA.Objects[hIndex]).TEXT := sItem;

                  //NIGHT TEXT
                  sItem := Trim( FoundLastChar( FoundStr(HTMLData.parString, 'Night</b><br>', '</td></tr>', iFS, iFS ) ) );

                  hIndex := hFirstIndex + (i - 1);
                  TSLNextDayWeather(DATA.Objects[hIndex]).NIGHT TEXT := sItem;

                  Application.ProcessMessages;
                end;
}


*)

              HTMLData := GetHTML('http://www.accuweather.com/world-forecast-15day.asp?locCode=' + sPlace + '&metric=1','','',10000,NO_CACHE, Info);
              if HTMLData.OK = True then
                begin
                  sFound := Trim(  FoundStr(HTMLData.parString, '<div class="content_box_435body" id="content_box_435_all15day">', '<div class="content_box_435bluenavbar">',1,iFS) );

//                  showmessage(sFound);

                  iFS:=1;
                  for i:= 1 to 15 do
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
{
                      sFound2 := Trim(  FoundStr(sFound, '<div class="forecastHeaderLeft">', '<div class="forecastHeaderLeft">',iFS,iFS) );
                      iFS:= iFS - Length('<div class="forecastHeaderLeft">') - 2;

                      showmessage(sFound2);
}
                      iFS := StrPosE(sFound,'<div class="forecastHeaderLeft">',iFS,False) + 1;

//                      showmessage(INTTOSTR(iFS));


                      //Day
                      sItem := Trim(  FoundStr(sFound, 'class="detailLink">', '</a>',iFS,iFS2) );
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Day := sItem;

{
                      //  Condition
                      sItem := Trim(  FoundStr(sFound, 'class="fcstSmTextBox">', '</div>',iFS,iFS2) ) ;
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;
}
                      //  Condition
                      sItem := Trim(  FoundStr(sFound, 'alt="', '"',iFS,iFS2) ) ;
                      sItem := HTMLToText(sItem);
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;




                      //  Temp. High
                      sItem := Trim(  FoundStr(sFound, 'High:', '&deg;C</div>',iFS,iFS2) ) ;
                      sUnit := 'C';
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;

                      //  Temp. Low
                      sItem := Trim(  FoundStr(sFound, 'Low:', '&deg;C</div>',iFS,iFS2) ) ;
                      sUnit := 'C';
                      hIndex:= DATA.Count - 1;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value     := sItem;
                      TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;

                      Application.ProcessMessages;
                    end;

//id="content_box_435_all15day"
                end;

(*


              for i:= 1 to 5 do
                begin
                  HTMLData := GetHTML('http://www.accuweather.com/world-forecast-details.asp?locCode=' + sPlace + '&fday=' + IntToStr( i ) + '&metric=1', Info);
                  if HTMLData.OK = True then
                    begin

                      DATA.Add('FORECAST');
                      hIndex:= DATA.Count - 1;
                      DATA.Objects[hIndex] := TSLNextDayWeather.Create;

                      sFound := Trim(  FoundStr(HTMLData.parString, 'class="forecastDetailDay"', '</table>',1,iFS) ) ;

                      if sFound<>'' then
                        begin
                          //Day
                          sItem := Trim(  FoundStr(sFound, 'class="textsmallbold">', '</div>',1,iFS) );

                          r1 := StrPosE(sItem, ' ',1,false);
                          if r1<>0 then
                            sItem := Trim( Copy(sItem, 1, r1 - 1) );

                          hIndex:= DATA.Count - 1;
                          TSLNextDayWeather(DATA.Objects[hIndex]).Day := sItem;


                          sItem := Trim(  FoundStr(sFound, '<td class="detailLeft">', '</td>',iFS,iFS) ) ;

                          //  Condition
                          sItem := Trim(  FoundStr(sFound, '<td class="detailLeft">', '</td>',iFS,iFS) ) ;
                          hIndex:= DATA.Count - 1;
                          TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;


                          //  Temp. High
                          sItem := Trim(  FoundStr(sFound, '<td class="detailRight">', '&deg;C</td>',iFS,iFS) ) ;
                          {showmessage(sItem);}
                          sUnit := 'C';
                          hIndex:= DATA.Count - 1;
                          TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.Value := sItem;
                          TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureHigh.ValueUnit := sUnit;

                        end;

                      sFound := Trim(  FoundStr(HTMLData.parString, 'class="forecastDetailNight"', '</table>',1,iFS) ) ;

                      if sFound<>'' then
                        begin
                          //Day
                          sItem := Trim(  FoundStr(sFound, 'class="textsmallbold">', '</div>',1,iFS) ) ;
{                          hIndex:= DATA.Count - 1;
                          TSLNextDayWeather(DATA.Objects[hIndex]).Day := sItem;
}

                          sItem := Trim(  FoundStr(sFound, '<td class="detailLeft">', '</td>',iFS,iFS) ) ;

                          //  Condition
                          sItem := Trim(  FoundStr(sFound, '<td class="detailLeft">', '</td>',iFS,iFS) ) ;
{                          hIndex:= DATA.Count - 1;
                          TSLNextDayWeather(DATA.Objects[hIndex]).Condition := sItem;

}                          //  Temp. Low
                          sItem := Trim(  FoundStr(sFound, '<td class="detailRight">', '&deg;C</td>',iFS,iFS) ) ;
                          sUnit := 'C';
                          hIndex:= DATA.Count - 1;
                          TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.Value     := sItem;
                          TSLNextDayWeather(DATA.Objects[hIndex]).TemperatureLow.ValueUnit := sUnit;

                        end;

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
