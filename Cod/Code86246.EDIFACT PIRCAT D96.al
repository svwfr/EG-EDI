codeunit 86246 "Edifact PRICAT D96"
{
    TableNo = EDI_Connection;

    trigger OnRun();
    begin
        EDIConnection := rec;
   
        CreatePRICAT();
    End;


    procedure CreatePRICAT();
    var
        Item:record item;
        SegmetString:text;
        SeasonCode:text[30];
        CatalogNo:text[30];
        Startingdate:date;
        Endingdate:Date;
        TermsOfDelivery:text[10];
        NotificationCode:text[1];
        ItemCrossref:text[30];
        LineNo:integer;


    begin

        EDIConnection."Order Counter" := Incstr(EDIConnection."Order Counter");
        EDIConnection.Modify;

        Customer.get(EDIConnection.code);
        CompanyInformation.GET();
        CreateFile(); 

        Fnutt := 39;

        WriteToStream('UNA:+.?');
        WriteToStream('UNB+UNOC:3+'+ CompanyInformation.gln + ':14+' + EDIConnection."Owner GLN" + ':14');
        WriteToStream('UNH' + '+' + EDIConnection."Order Counter" + '+' + 'PRICAT:D:01B:UN:SPORTA');
        WriteToStream('BGM+9:::' + SeasonCode + '+' + CatalogNo + '9');
        WriteToStream('DTM+137:'+ConvertOutDate(TODAY) + ':102');
        WriteToStream('DTM+157:'+ConvertOutDate(StartingDate) + ':102');
        WriteToStream('DTM+21E:'+ConvertOutDate(EndingDate) + ':102');
        WriteToStream('BY+'+EDIConnection.Code+'::9');
        WriteToStream('SU+' + CompanyInformation.GLN + '::9');
        WriteToStream('TOD+4++' + TermsOfDelivery);
        WriteToStream('PGI+2'); 

        If Item.FindSet then
        repeat
            LineNo := LineNo + 1;
            WriteToStream('LIN+' + format(LineNo) + '+' + NotificationCode + '+' + ItemCrossref + ':EN');
            WriteToStream('PIA+1' + Item."No.");
            WriteToStream('IMD+F++:::' + Item.Description);
            WriteToStream('IMD+C++CU');
            //IMD Merkenavn ?
            //IMD Produkt type
            //IMD en standard
            //IMD Environmental label
            //IMD Colour code
            //IMD Colour description
            //IMD Size type
            //IMD Size
            //IMD Ordering unit
            //IMD Age limit
            //IMD Prescription requirement
            //IMD Display unit
            //IMD Smallest unit
            //IMD Package split
            //IMD Genetically modified product
            //IMD Ecological
            //IMD Invoice method
            //MEA Unit price factor
            //MEA Lowest unit and quantity
            //QTY Number of lower level units
            //QTY Production minimum
            //HAN Handling instructions
            //ALI Country of origin
            //DTM Available from date
            //DTM Available to date
            //DTM Lead time
            //DTM Delivery deadlines
            //DTM Delivery windows
            //RFF Picture references
            //RFF Customs tariff number
            //RFF Supplier’s order (article) number
            //FTX Ship from location
            //FTX Supplier’s model number
            //FTX Advertising information
            //FTX Technical information
            //TAX Value added tax
            //PRI Gross unit price
            //CUX Currency
            //DTM Date/time period
            //PRI Suggested retail price
            //CUX Currency
            //DTM Date/time period
            //PRI Net price pre-order
            //CUX Currency
            //DTM Date/time period
            //PRI Net price supplementary order
            //CUX Currency
            //DTM Date/time period
            //ALC Early payment allowance
            //DTM Date/time period
            //PCD Percentage detail
            //ALC Early payment allowance retailer
            //DTM Date/time period
            //PCD Percentage detail
            //ALC Supplementary allowance
            //DTM Date/time period
            //PCD Percentage detail
            //ALC Supplementary allowance retailer
            //DTM Date/time period
            //PCD Percentage detail
            //PAC Package type
            //MEA Width
            //MEA Depth
            //MEA Height
            //MEA Gross weight
        
        Until Item.next = 0;

        WriteToStream('UNT+' + format(RecCint) + EDIConnection."Order Counter");

        ExportFile.CLOSE();

        Commit;
    end;

 

    procedure CreateFile();
    var
       exportFileName: text;
    begin
        exportFileName := DelChr(EDIConnection."File Path Out",'>','\') + '\' + Customer."No." + '.PriCat'; 
        exportFile.CREATE(exportFilename);
        exportFile.CREATEOUTSTREAM(exportStream);
    end;

    procedure WriteToStream(vString : Text[1024]);
    begin
        exportStream.WRITETEXT(vString);
        IF WriteCRToFile THEN
            exportStream.WRITETEXT();  

        RecCint := RecCint + 1;
    end;

    Procedure FormatNumber(DEC:Decimal): text[30];
    var
        TextAmount:text[30];
        Len:Integer;
        Pos:Integer;
    begin
        IF Dec = 0 THEN
            TextAmount:= '0,00'
        ELSE BEGIN
            TextAmount:= FORMAT(Dec);
            Len:=STRLEN(TextAmount);
            Pos:= STRPOS(TextAmount,',');
            IF Pos = 0 THEN
               TextAmount:= TextAmount + ',00'
            ELSE BEGIN
                IF Len = Pos THEN TextAmount:= TextAmount + '00';
                IF Len - Pos = 1 THEN TextAmount:= TextAmount + '0';
                IF Len - Pos >= 2 THEN TextAmount:= COPYSTR(TextAmount,1,Pos+2);
            END;
        END;

        IF ABS(Dec) >= 1000 THEN BEGIN
            Len:= STRLEN(TextAmount);
            TextAmount:= COPYSTR(TextAmount,1,Len-7) + COPYSTR(TextAmount,Len-5,6);
            IF ABS(Dec) >= 1000000 THEN BEGIN
                Len:= STRLEN(TextAmount);
                TextAmount:= COPYSTR(TextAmount,1,Len-10) + COPYSTR(TextAmount,Len-8,9);
            END;
        END;
        TextAmount:= CONVERTSTR(TextAmount,',','.');
        EXIT(TextAmount);
    end;

    Procedure ShortDate(Impdate : Date) : Text[30];
    var
        RetDat: text[20];
        Year : Text[4];
        Mon : Text[2];
        Day : text[2];
    begin
        IF Impdate <> 0D THEN BEGIN
            RetDat:= FORMAT(Impdate);
            Year:= COPYSTR(RetDat,7,2);
            mon:= COPYSTR(RetDat,4,2);
            day:= COPYSTR(RetDat,1,2);
            RetDat:= Year+mon+day;
            EXIT(RetDat);
        END;    
    End;

    Procedure FormatTime(Time : Time) : Text[30];
    Var
        RetTime: text[20];
        Hour: text[2];
        Minute: Text[2];
        Sec: text[2];

    Begin
        IF Time <> 0T THEN BEGIN
            RetTime:= FORMAT(Time);
            Hour:= COPYSTR(RetTime,1,2);
            Minute:= COPYSTR(RetTime,4,2);
            Sec:= COPYSTR(RetTime,7,2);
            //   RetTime:= Hour + Minu + Sec;
            RetTime:= Hour + Minute;
            IF (RetTime[1] < '1') OR (RetTime[1] > '2') THEN RetTime[1]:= '0';
            EXIT(RetTime);
        END;
    End;

    procedure ConvertOutDate(InDate : Date) OutDate : Text[8];
    var
        Month: text[2];
        Day:text[2];

    begin
        IF InDate = 0D THEN ERROR('ingen dato');
        OutDate := FORMAT(DATE2DMY(InDate, 3));
        Month := FORMAT(DATE2DMY(InDate, 2));
        IF STRLEN(Month) = 1 THEN
            Month := '0' + Month;
        OutDate := OutDate + Month;
        Day := FORMAT(DATE2DMY(InDate, 1));
        IF STRLEN(Day) = 1 THEN
            Day := '0' + Day;
        OutDate := OutDate + Day;
    End;

    var
        EDIConnection: Record EDI_Connection;
        Customer: record Customer;
        CompanyInformation:record "Company Information";
        EDIMgt: codeunit "EDI_Mgt";
        ExportFile: file;
        ExportStream: OutStream;

        WriteCrToFile: Boolean;
        Fnutt: char;
        RecCint:integer;

}