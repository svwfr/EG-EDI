table 86230 EDI_Connection
{
    DataClassification = ToBeClassified;
    Caption = 'Edi Connection';

    fields
    {
        field(1;Code;Code[20])
        {
            Caption = 'Code';
        }
        field(2; "Owner GLN"; Code[20])
        {
            Caption = 'Sender GLN';
            DataClassification = CustomerContent;

            trigger OnValidate();
            var
                EdiConnection: Record EDI_Connection;

            begin
                If "GLN Type" = "GLN Type"::Agreement Then Begin
                    EdiConnection.setrange(Code,code);
                    EdiConnection.setfilter("GLN Type",'<>%1',"GLN Type"::Agreement);
                    EdiConnection.modifyall("Owner GLN","Owner GLN");
                end;
            end;
        }

        field(4; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate();
            begin
                IF cust.GET("Customer No.") THEN
                    "Customer Name" := cust.Name
                ELSE
                    "Customer Name" := '';
            end;
        }
        field(5; "Customer Name"; Text[50])
        {
            Caption = 'Customer Name';
        }
        field(6; "GLN Type"; Option)
        {
            Caption = 'GLN Type';
            OptionMembers = " ","By", "DP", "IV", , , , , ,, ,"Agreement" ;
        }
        field(7; GLN; Code[20])
        {
            Caption = 'GLN';
        }
        field(8; "No.";Code[250])
        {
            Caption = 'No.';
            TableRelation = IF ("GLN Type" = CONST(By)) Customer
                            ELSE IF ("GLN Type"=CONST(IV)) Customer
                            Else If ("GLN Type" =CONST(DP)) "Ship-to Address".Code where ("Customer No." = field("Customer No."));

        }
        
        field(10; "EDI Type"; Code[20])
        {
            Caption = 'EDI Type';
            TableRelation = EDI_Types;

            trigger OnValidate();
            var
                EdiConnection: Record EDI_Connection;

            begin
                If "GLN Type" = "GLN Type"::Agreement Then Begin
                    EdiConnection.setrange(Code,code);
                    EdiConnection.setfilter("GLN Type",'<>%1',"GLN Type"::Agreement);
                    EdiConnection.modifyall("EDI Type","EDI Type");
                end;
            end;
        }
        field(11; Order; Boolean)
        {
            Caption = 'Order';
        }
        field(12; Shipment; Boolean)
        {
            Caption = 'Shipment';
        }
        field(13; Invoice; Boolean)
        {
            Caption = 'Invoice';
        }
        field(14; "Validate GLN"; Boolean)
        {
            Caption = 'Validate Gln';
        }
        Field(15;"Allow Edi AdHock"; Boolean)
        {
            Caption = 'Allow AdHock Edi';
        }
        Field(16;"Credited Invoice Required"; Boolean)
        {
            Caption = 'Credited Invoice Required';
        }
        field(17;"Empty Order Date when Adhock";Boolean)
        {
            Caption = 'Empty Order Date when Adhock';
        }
        field(18;"Skip By VAT Registration No.";Boolean)
        {
            Caption = 'Skip By VAT Registration No.';
        }
        field(20;"Item (Charge)"; Code[20])
        {
            Caption = 'Item Charge';
        }
        field(21;INVRPT;Boolean)
        {
            Caption = 'Inv. Report';
        }
        Field(22;"INVRPT Location Filter";Text[250])
        {
            Caption = 'InvRpt Location Filter';
            TableRelation = Location;
            ValidateTableRelation = False;
        }
        field(40; "File Path in"; Text[250])
        {
            Caption = 'File Path In';
        }
        field(41; "File Path Out"; Text[250])
        {
            Caption = 'File Path Out';
        }
        field(42; "File Path Archive Inn"; Text[250])
        {
            Caption = 'File Path Archive In';
        }
        field(43; "File Path Archive Out"; Text[250])
        {
            Caption = 'File Path Archive Out';
        }
        field(50; "Filter Incomming Orders"; Text[250])
        {
            Caption = 'Filter Incoming Orders';
        }
        field(51; "File Name Orders"; Text[250])
        {
            Caption = 'File Name Orders';
        }
        field(52; "File Name Shipment"; Text[250])
        {
            Caption = 'File Name Shipment';
        }
        field(53; "File Name Invoice"; Text[250])
        {
            Caption = 'File Name Invoice';
        }
        field(54; "File Name Credit Memo"; Text[250])
        {
            Caption = 'File Name Cr. Memo';
        }
        field(55; "File Name INVRPT"; Text[250])
        {
            Caption = 'File Name InvRpt';
        }
        field(56; "File Name Pricat"; Text[250])
        {
            Caption = 'File Name Pricat';
        }
        field(70;"Gln Customer";Option)
        {
            Caption = 'Gln Customer';
            OptionMembers = "BY","DP";
        }
        field(71;"Gln Invoice";Option)
        {
            Caption = 'Gln Invoice';
            OptionMembers = "IV", "BY";
        }
        field(72;"Gln Shipment";Option)
        {
            Caption = 'Gln Shipment';
            OptionMembers = " ", "DP";
        }
        field(99; "Action Type"; Option)
        {
            Caption = 'Action Type';
            OptionMembers = " ","ORDERS", "ORDERCONFIRMATION", "ORDERSP", "INVOICE", "INVRPT","PRICAT";
        }
        field(100;"Order Counter";code[10])
        {
            Caption = 'Order Counter';
        }
        field(101;"Invoice Counter";Code[10])
        {
            Caption = 'Invoice Counter';
        }
        field(102;"InvRPT Counter";Code[10])
        {
            Caption = 'InvRpt Counter';
        }

    }

    keys
    {
        key(Key1; "Code", "Customer No.", "GLN Type", GLN)
        {
            Clustered = true;
        }
    }


    fieldgroups
    {
    }

   
    var
        cust: Record Customer;

    procedure CodeDescription(): Text[50];
    var
        ShipToAddress: Record "Ship-to Address";
        
    begin
        IF "GLN Type" = "GLN Type"::"By" THEN BEGIN
            IF cust.GET("No.") THEN
                EXIT(cust.Name);
        END
        ELSE IF "GLN Type" = "GLN Type"::"IV" THEN BEGIN
                IF cust.GET("No.") THEN
                    EXIT(cust.Name)
            END
            ELSE IF "GLN Type" = "GLN Type"::"DP" THEN
                    IF ShipToAddress.GET("Customer No.", "No.") THEN
                        EXIT(ShipToAddress.City);


        EXIT('');
    end;

    trigger OnInsert();
    begin
    end;

    trigger OnModify();
    begin
    end;

    trigger OnDelete();
    begin
    end;

    trigger OnRename();
    begin
    end;

}