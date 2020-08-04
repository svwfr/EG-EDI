codeunit 86244 "EDIFACT INVOIC D96"
{
    TableNo = "Sales Invoice Header";
    Permissions = tabledata 112 = rimd;

    trigger OnRun();
    begin
        SalesInvHeader.Get(Rec."No.");
        CreateInvoice();
    End;

    procedure CreateInvoice();
    var
        DocumentLogg:Record EDI_Document_Logg;
        ChangeStatus:code[10];
        RestOrder:Boolean;
        ActionRequest:text[4];
        SegmentString:text;

    begin
        SalesInvHeader.Calcfields("Amount Including VAT");
        If SalesInvHeader."Amount Including VAT" = 0 Then begin
            SalesInvHeader.Get(SalesInvHeader."No.");
            SalesInvHeader."EDI Created" := Today;
            SalesInvHeader.Modify;
            
            EDIHeader.Get(SalesInvHeader."Edi Order-ID");
            EDIHeader."Invoice send" := Today;
            EDIHeader.Modify;
            Exit;    
        End;
        
        Fnutt := 39;

        EDIMgt.FindExportEDIConnection(SalesInvHeader."Sell-to Customer No.", EDIConnection,True,'I');
        EDIHeader.Get(SalesInvHeader."Edi Order-ID");
        Customer.get(SalesInvHeader."Bill-to Customer No.");
        CompanyInformation.GET();

        If EDIHeader."GLN SU" = '' then
            EDIHeader."GLN SU" := CompanyInformation.GLN;

        EDIHeader.Testfield("GLN SU");

        CreateFile(); 
        FindVatCodes();
        CalculateTotals();
        CreateInvoiceHeader();

        SalesInvLine.setrange("EDI Item (Charge)",False);
        SalesInvLine.SetFilter(Quantity,'<>0');
        
        If SalesInvLine.FindSet then
        repeat
            CreateInvoiceLine();
        Until SalesInvLine.Next = 0;

        FinishInvoiceHeader;
        ExportFile.CLOSE();
        
        SalesInvHeader.Get(SalesInvHeader."No.");
        SalesInvHeader."EDI Filcounter" := EDIConnection."Invoice Counter";
        SalesInvHeader."EDI Created" := Today;
        SalesInvHeader.Modify;

        EDIHeader."Invoice send" := Today;
        EDIHeader.Modify;

        DocumentLogg.InsertEntry(EDIHeader,EDIDocumentType,EDIConnection."Invoice Counter",DocumentLogg."Document Type"::Invoice,SalesInvHeader."No.",ExportFileName);
        Commit;

    end;
  
    procedure CreateInvoiceHeader()
    var
        PaymentTerms:Record "Payment Terms";
        ShipmentHeader:Record "Sales Shipment Header";
        SegmentString:text;
        DiscDueDate:Date;

    begin
        If SalesInvHeader."Shipment Date" > SalesInvHeader."Document Date" Then
            SalesInvHeader."Shipment Date" := SalesInvHeader."Document Date";

        RefNo := 1;

        SegmentString := EDIHeader."GLN SU" + ':14' + '+' + EDIHeader."GLN Owner" + ':14'+ 
            '+' + ShortDate(TODAY)+':' + FormatTime(TIME) +
            '+' + EDIConnection."Invoice Counter";

        IF TestFlagg THEN
            SegmentString := '++++0++1' +ShortDate(TODAY)+':' + FormatTime(TIME);

        EDIDocumentType := 'INVOIC:D:96A:UN:SPORTA';


        WriteToStream('UNA:+.? ');
        WriteToStream('UNB+UNOC:3+' + SegmentString);
        WriteToStream('UNH+' + Format(RefNo) + '+' + EDIDocumentType);   
        WriteToStream('BGM+' + '380' + '+' + SalesInvHeader."No.");
        WriteToStream('DTM+137:' + ConvertOutDate(SalesInvHeader."Document Date") +':102'); 
        WriteToStream('DTM+35:' + ConvertOutDate(SalesInvHeader."Shipment Date") +':102'); 

        //If EDIHeader."EDI message Type" <> '' then
        //    WriteToStream('FTX+AAI+1++'+EDIHeader."EDI message Type")
        //Else If SalesInvHeader."Edi Adhock Order" Then
        //    WriteToStream('FTX+AAI+1++226');

        WriteToStream('RFF' + '+' + 'ON:' + EDIHeader."Customer Order No.");

        //DTM Ved adhock skal ikke ordredato fylles ut
        If Not (EDIConnection."Empty Order Date when Adhock" and EDIHeader."Adhock Order") Then
            WriteToStream('DTM+171:' + ConvertOutDate(EDIHeader."Order Date") +':102'); 

        If SalesInvHeader."Order No." <> '' then
            WriteToStream('RFF' + '+' + 'VN:' + SalesInvHeader."Order No.");

        ShipmentHeader.setrange("Order No.",SalesInvHeader."Order No.");
        If ShipmentHeader.FindLast Then Begin
            WriteToStream('RFF' + '+' + 'AAK:' + ShipmentHeader."No.");
            WriteToStream('DTM+171:' + ConvertOutDate(ShipmentHeader."Posting Date") +':102'); 
        end;

        SetNad();

        If SalesInvHeader."Currency Code" = '' then
            SegmentString := 'CUX+2:NOK:4'
        else
            SegmentString := 'CUX+2:'+ SalesInvHeader."Currency Code" + ':4';
        WriteToStream(SegmentString);

        WriteToStream('PAT+3');
        WriteToStream('DTM+3:' + ConvertOutDate(SalesInvHeader."Document Date") +':102'); 
        WriteToStream('DTM+13:' + ConvertOutDate(SalesInvHeader."Due Date") +':102'); 

        If SalesInvHeader."Payment Discount %" <> 0 then begin
            WriteToStream('PAT+22');
            WriteToStream('DTM+12:' + ConvertOutDate(SalesInvHeader."Pmt. Discount Date") + ':102'); 
            WriteToStream('PCD+12:' + FormatNumber(SalesInvHeader."Payment Discount %") + ':13');
        end;
        
        if SalesInvHeader."Shipment Method Code" <>  '' then
            WriteToStream('TOD+3++' + SalesInvHeader."Shipment Method Code");

        If SalesInvHeader."Invoice Discount Amount" <> 0 Then Begin
            If SalesInvHeader."Payment Discount %" <> 0 then
                WriteToStream('PCD+12' + FormatNumber(SalesInvHeader."Payment Discount %") + ':13');

            WriteToStream('ALC+A++++CAC');
            WriteToStream('MOA+8:' + FormatNumber(SalesInvHeader."Invoice Discount Amount"));       
        End;
    End;

    Procedure FinishInvoiceHeader();
    Var 
        SumVatLineAmt:array[100] of decimal;
        SumVatAmount:array[100] of decimal;
        VatPct:array[100] of decimal;
        VatIdx:integer;

    begin

        SalesInvHeader.calcfields("Amount Including VAT",Amount);
        WriteToStream('UNS+S');
        WriteToStream('CNT+2:' + FORMAT(LineCint,0,'<integer>'));
        WriteToStream('MOA+86:'  + FormatNumber(SalesInvHeader."Amount Including VAT"));                            //Invoice total amounts
        WriteToStream('MOA+150:' + FormatNumber(SalesInvHeader."Amount Including VAT" - SalesInvHeader.Amount));    
        WriteToStream('MOA+203:' + FormatNumber(LineAmount));  
        If RoundingAmount <> 0 then                                                                                 
            WriteToStream('MOA+165:' + FormatNumber(RoundingAmount));                                               
        

        IF TmpVATAmountLine.FINDFIRST THEN BEGIN
            VatIdx        := 0;
            REPEAT //Sum up all lines with same VAT-%
                VatIdx := TmpVATAmountLine."VAT %"+1;  //To avoid idx = 0
                SumVatLineAmt[VatIdx] := SumVatLineAmt[VatIdx] + TmpVATAmountLine."Line Amount";
                SumVatAmount[VatIdx] := SumVatAmount[VatIdx] + TmpVATAmountLine."VAT Amount";
                VatPct[VatIdx] := TmpVATAmountLine."VAT %";
            UNTIL TmpVATAmountLine.NEXT = 0;
        
            VatIdx := 1;
            REPEAT  //One TAX line per VAT %
                IF (SumVatLineAmt[VatIdx] <> 0) OR (SumVatAmount[VatIdx] <> 0) THEN BEGIN
                    WriteToStream('TAX+7+VAT++' + FormatNumber(SumVatLineAmt[VatIdx]) + '+:::' + FormatNumber(VatPct[VatIdx]) + '+S');
                    WriteToStream('MOA+176:' + FormatNumber(SumVatAmount[VatIdx])); //SUM All charges
                    SumVatLineAmt[VatIdx] := 0;
                    SumVatAmount[VatIdx] := 0;
                END;
                VatIdx := VatIdx +1;
            UNTIL VatIdx = 100;
        End;

        If FreightAmount <> 0 then begin
            WriteToStream('ALC+C++++FC');
            WriteToStream('MOA+8:'+formatnumber(FreightAmount));
        End;

        WriteToStream('UNT+' + FORMAT(RecCint-1,0,'<integer>') + '+' + FORMAT(RefNo));
        WriteToStream('UNZ+' + Format(RefNo) + '+' + EDIConnection."Invoice Counter");
    End;

    Procedure CreateInvoiceLine();
    var
        EdiMgt:Codeunit EDI_Mgt;
        SegmentString:text;
        Ean:Code[50];


    begin

        If Not EDIOrderLine.Get(SalesInvHeader."Edi Order-ID",SalesInvLine."EDI Order Line") then Begin
            Clear(EDIOrderLine);
            IF EdiMgt.CheckEAN(SalesInvLine."No.",SalesInvLine."Unit of Measure Code",EAN,false) then begin
                EDIOrderLine."PO Item No." := EAN;
                EDIOrderLine."PO Description" := SalesInvLine.Description;
            End
            Else
                Error(StrSubstNo(Txt1000,SalesInvLine."No."));
        End;

        LineCint := LineCint + 1;

        SegmentString := FORMAT(LineCint,0,'<integer>');
        SegmentString := SegmentString + '+' +FORMAT(EDIOrderLine.ActionRequest)+ '+' + EDIOrderLine."PO Item No." + ':EN::9';

        WriteToStream('LIN+'+ SegmentString);
        WriteToStream('PIA+1+' + SalesInvLine."No."+':SA');
        WriteToStream('IMD+F++:::' + Delchr(Delchr(EDIOrderLine."PO Description",'=',Fnutt),'=',':+?'));
        WriteToStream('QTY+47:'+ FormatNumber(SalesInvLine.Quantity)); 
   
        WriteToStream('MOA+203:'+ FormatNumber(SalesInvLine."Line Amount")); 
        WriteToStream('PRI+AAB:'+ FormatNumber(SalesInvLine."Unit Price")); 

        If EDIOrderLine."PO Referance" <> '' then
            WriteToStream('RFF+ON:'+ EDIOrderLine."PO Referance");

        WriteToStream('RFF+OP:'+ EDIHeader."Customer Order No." + ':' + Format(EDIOrderLine."Po Line No.",0,'<integer>'));
        WriteToStream('TAX+7+VAT+++:::' + FormatNumber(SalesInvLine."VAT %") + '+S');
        WriteToStream('MOA+124:'+ FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine."Line Amount"));

        WriteToStream('ALC+A++++DI');
        WriteToStream('PCD+3:' + Formatnumber(SalesInvLine."Line Discount %") + ':13');
        WriteToStream('MOA+8:' + Formatnumber(SalesInvLine."Line Discount Amount"));

     End;

    Procedure SETNAD();
    var
        Cust:Record Customer;
        DocumentTools:codeunit DocumentTools;
        SegmentString: Text;
        GiroAmountKr:text[20];
        GiroAmountkre:text[4];
        CheckDigit:Text[2];
        GiroKid:text[30];
        KIDError:Boolean;
        RegionCode:Text[3];
        CustName:text[50];
        CustAdress:text[50];
        CustCity:text[50];
        CustPostCode:text[50];

    begin
        CustName := SalesInvHeader."Sell-to Customer Name";
        CustAdress := SalesInvHeader."Sell-to Address 2";
        CustCity := SalesInvHeader."Sell-to City";
        CustPostCode:= SalesInvHeader."Sell-to Post Code";

        GetCustAddress(EDIHeader."GLN BY",CustName,CustAdress,CustCity,CustPostCode);
        
        SegmentString := 'NAD+BY+' + EDIHeader."GLN BY" + '::9++' + 
                        CustName + '+' +
                        CustAdress  + '+' + 
                        CustCity + '++' +
                        CustPostCode;
        WriteToStream(SegmentString);

        If Not EDIConnection."Skip By VAT Registration No." then begin
            Cust.Get(SalesInvHeader."Sell-to Customer No.");
            If Cust."VAT Registration No." <> '' Then begin
                SegmentString := 'RFF+VA:NO' + Delchr(Cust."VAT Registration No.",'=',Delchr(Cust."VAT Registration No.",'=','0123456789')) + 'MVA';
                WriteToStream(SegmentString);
            end;
        End;

        DocumentTools.SetupGiro(TRUE,1,
            SalesInvheader."No.",SalesInvHeader."Bill-to Customer No.",SalesInvHeader."Amount Including VAT",
            SalesInvHeader."Currency Code",GiroAmountKr,GiroAmountkre,CheckDigit,GiroKid,KIDError);

        If SalesInvHeader."Sell-to Contact" <> '' then
            WriteToStream('CTA+PD' + SalesInvHeader."Sell-to Contact");

        //DP
        IF  EDIHeader."GLN DP" <> '' Then Begin
            CustName := SalesInvHeader."Ship-to Name";
            CustAdress := SalesInvHeader."Ship-to Address 2";
            CustCity := SalesInvHeader."Ship-to City";
            CustPostCode:= SalesInvHeader."Ship-to Post Code";

            GetcustAddress(EDIHeader."GLN DP",CustName,CustAdress,CustCity,CustPostCode);

            SegmentString := 'NAD+DP+' + EDIHeader."GLN DP" + '::9++' + 
                CustName + '+' +
                CustAdress  + '+' + 
                CustCity + '++' +
                CustPostCode;
            WriteToStream(SegmentString);
        End;

        //IV
        If EDIHeader."GLN IV" <> '' Then begin
            CustName := SalesInvHeader."Bill-to Name";
            CustAdress := SalesInvHeader."Bill-to Address 2";
            CustCity := SalesInvHeader."Bill-to City";
            CustPostCode:= SalesInvHeader."Bill-to Post Code";

            GetcustAddress(EDIHeader."GLN IV",CustName,CustAdress,CustCity,CustPostCode);

            SegmentString := 'NAD+IV+' + EDIHeader."GLN IV" + '::9++' + 
                CustName + '+' +
                CustAdress  + '+' + 
                CustCity + '++' +
                CustPostCode;
            WriteToStream(SegmentString);
        End;

        SegmentString := 'NAD+SU+' + EDIHeader."GLN SU" + '::9++' + 
            CompanyInformation.Name + '+' +
            CompanyInformation.Address  + '+' + 
            CompanyInformation.City + '++' +
            CompanyInformation."Post Code";
        WriteToStream(SegmentString);
        

        If CompanyInformation."Bank Account No." <> '' then Begin
            SegmentString := 'FII+RH+' + delchr(CompanyInformation."Bank Account No.",'=',Delchr(CompanyInformation."Bank Account No.",'=','0123456789'));
            WriteToStream(SegmentString);
        End;

        IF GiroKid <> '' then 
          WriteToStream('RFF+PQ:' + Girokid);

        SegmentString := 'RFF+VA:NO' + delchr(CompanyInformation."VAT Registration No.",'=',delchr(CompanyInformation."VAT Registration No.",'=','0123456789'))+'MVA';
        WriteToStream(SegmentString);
    End;
 
    Procedure GetCustAddress("GLN No.":code[20];Var CustName:text[50];Var CustAddress:text[50];Var CustCity:text[50];Var CustPostCode:text[50]);
    var
        Cust:record Customer;
        EDIConn:Record EDI_Connection;
    begin
        EDIConn.SetRange("GLN Type",EDIConn."GLN Type"::By);
        EDIConn.setrange(GLN,"GLN No.");
        If EDIConn.FindFirst Then 
            If Cust.Get(EDIConn."No.") then Begin
                If delchr(cust."Edi Customer Name",'=',' ') <> '' Then begin
                    CustName := Cust."Edi Customer Name";
                    CustAddress := cust."Edi Address";
                    CustCity := Cust."Edi City";
                    CustPostCode := cust."Edi Post Code";
                End
                Else begin
                    CustName := Cust.Name;
                    CustAddress := cust."Address 2";
                    CustCity := Cust.City;
                    CustPostCode := cust."Post Code";
                End;
            End;
    End;

    procedure FindVatCodes();
    var
        VatPostSetup:Record "VAT Posting Setup";
        VatExist: Boolean;
        i:integer;

    begin
        NoofVatCodes:= 0;
        VatPostSetup.RESET;
        IF VatPostSetup.FIND('-') THEN BEGIN
        REPEAT
            VatExist:= FALSE;
            IF VatPostSetup."VAT %" <> 0 THEN BEGIN
                IF NoofVatCodes = 0 THEN BEGIN
                    NoofVatCodes:= 1;
                    VATCode[1]:= VatPostSetup."VAT %";
                END ELSE BEGIN
                    FOR i:= 1 TO NoofVatCodes DO BEGIN
                    IF VATCode[i] = VatPostSetup."VAT %" THEN VatExist:= TRUE;
                    END;
                    IF NOT VatExist THEN BEGIN
                    NoofVatCodes:= NoofVatCodes + 1;
                    VATCode[NoofVatCodes]:= VatPostSetup."VAT %";
                    END;
                END;
            END;
        UNTIL VatPostSetup.NEXT = 0;
        END;
    end;

    Procedure CalculateTotals();
    vAR 
        i:Integer;
    begin
        TmpVatAmountLine.DELETEALL;
        SalesinvLine.SETRANGE("Document No.",SalesInvHeader."No.");
        IF SalesinvLine.Findset THEN
        REPEAT
            TmpVatAmountLine.INIT;
            TmpVatAmountLine."VAT Identifier" := SalesinvLine."VAT Identifier";
            TmpVatAmountLine."VAT Calculation Type" := SalesinvLine."VAT Calculation Type";
            TmpVatAmountLine."Tax Group Code" := SalesinvLine."Tax Group Code";
            TmpVatAmountLine."VAT %" := SalesinvLine."VAT %";
            TmpVatAmountLine."VAT Base" := SalesinvLine.Amount;
            TmpVatAmountLine."VAT Amount" := SalesinvLine."Amount Including VAT" - SalesinvLine.Amount;
            TmpVatAmountLine."Amount Including VAT" := SalesinvLine."Amount Including VAT";
            TmpVatAmountLine."Line Amount" := SalesinvLine."Line Amount";
            IF SalesinvLine."Allow Invoice Disc." THEN
                TmpVatAmountLine."Inv. Disc. Base Amount" := SalesinvLine."Line Amount";
            TmpVatAmountLine."Invoice Discount Amount" := SalesinvLine."Inv. Discount Amount";
            TmpVatAmountLine.Quantity := SalesinvLine."Quantity (Base)";
            TmpVatAmountLine."Calculated VAT Amount" := SalesinvLine."Amount Including VAT" - SalesinvLine.Amount - SalesinvLine."VAT Difference";
            TmpVatAmountLine."VAT Difference" := SalesinvLine."VAT Difference";
            TmpVatAmountLine.InsertLine;

            SumAmt[1]:= SumAmt[1] + SalesInvLine."Amount Including VAT";
            SumAmt[2]:= SumAmt[2] + SalesInvLine.Amount;
            SumAmt[3]:= SumAmt[3] + SalesInvLine."Line Amount";
            SumAmt[4]:= SumAmt[4] + SalesInvLine."Amount Including VAT" - SalesInvLine.Amount;
            SumAmt[5]:= SumAmt[5] + SalesInvLine.Amount - SalesInvLine."Line Amount";
            SumAmt[6]:= SumAmt[6] + SalesInvLine."Line Discount Amount";

            FOR i:= 1 TO NoofVatCodes DO BEGIN
                IF VATCode[i] = SalesInvLine."VAT %" THEN
                    SumAmt[i+6]:= SumAmt[i+6] + SalesInvLine."Amount Including VAT" - SalesInvLine.Amount;
            END;
            IF (SalesinvLine.Type = SalesinvLine.Type::Item) and (Not SalesInvLine."EDI Item (Charge)") Then Begin
                AmountInclVAT := AmountInclVAT + SalesInvLine."Amount Including VAT";
                LineAmount := LineAmount + SalesInvLine.Amount;
            End 
            else If SalesinvLine.Type = SalesinvLine.Type::"G/L Account" Then begin
                RoundingAmount := RoundingAmount + SalesInvLine.Amount;
            End
            Else
                FreightAmount := FreightAmount + SalesInvLine.Amount;

        UNTIL SalesinvLine.NEXT = 0;
    end;

    procedure CreateFile();
    var
        FileName: Text;
        FilePath: Text;
    begin
       
        EdiMgt.GetFileNameOut(EDIConnection,'IV',False,FilePath,FileName);
        FileName := FilePath + '\' + StrSubstNo(FileName,SalesInvHeader."No.",EDIConnection."Owner GLN",CurrentDateTime);

        exportFile.CREATE(Filename);
        exportFile.CREATEOUTSTREAM(exportStream);  

        exportFileName := filemgt.GetFileName(FileName);
    end;

    procedure WriteToStream(vString : Text[1024]);
    begin
        exportStream.WRITETEXT(delchr(vString,'=',Fnutt) + format(Fnutt));
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
        IF InDate = 0D THEN ERROR('Date Missing');
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
        EDIHeader: record "EDI Header";
        EDIOrderLine: record "EDI Lines";
        SalesInvHeader: record "Sales Invoice Header";
        SalesInvLine: record "Sales Invoice Line";
        SalesCrMemoHeader:Record "Sales Cr.Memo Header";
        TmpVatAmountLine:record "VAT Amount Line" temporary;
        EDIConnection: Record EDI_Connection;
        Customer: record Customer;
        CompanyInformation:record "Company Information";
        EDIMgt: codeunit "EDI_Mgt";
        FileMgt:Codeunit "File Management";
        ExportFile: file;
        ExportStream: OutStream;
        WriteCrToFile: Boolean;
        RefNo:integer;
        RecCint: Integer;
        LineCint: Integer;
        Fnutt: char;
        TestFlagg:Boolean;
        AmountInclVAT: decimal;
        LineAmount:decimal;
        RoundingAmount:decimal;
        InvoiceRndAmt:Decimal;
        InvoiceRndAmtInclVAT:Decimal;
        FreightAmount:Decimal;
        VATAmount:Decimal;
        VATCode:array[10] of decimal;
        NoofVatCodes:integer;
        SumAmt: array[10] of decimal;
        EDIDocumentType:text[30];
        ExportFileName:text[250];

        Txt1000:Label 'Varenr %1 manglere GTIN';
}