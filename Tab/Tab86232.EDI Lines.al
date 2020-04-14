table 86232 "EDI Lines"
 {

    DataClassification = ToBeClassified;
    Caption = 'Edi Lines';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "PO Item Type"; Option)
        {
            Caption = 'PO Item Type';
            OptionMembers = " ",SA,GTIN,EN;
        }
        field(4; "PO Item No."; Text[50])
        {
            Caption = 'PO Item No.';
        }
        field(5; "Suppliers Model Number";Code[30])
        {
            Caption = 'Suppliers Model Number';
        }
        field(6; "PO Quantity" ; Decimal)
        {
            Caption = 'PO Quantity';
        }
        field(7; "PO Unit Of Measure";Code[30])
        {
            Caption = 'PO Unit Of Measure';
        }
        field(8; "PO Sales Price";Decimal)
        {
            Caption = 'PO Sales Price';
        }
        field(9; "PO Line No.";Decimal)
        {
            Caption = 'PO Line No.';
        }
        field(10; "PO Delivery Date";Date)
        {
            Caption = 'PO Delivery Date';
        }
        field(11; "PO Line Discount";Decimal)
        {
            Caption = 'PO Line Discount';
        }
        field(15; "PO Referance"; text[30])
        {
            Caption = 'PO Referance';
        }
        field(50; "SO Order No.";Code[30])
        {
            Caption = 'SO Order No.';
        }
        field(51; "SO Line No.";Integer)
        {
            Caption = 'SO Line No.';
        }
        field(52; "SO Item No.";code[20])
        {
            Caption = 'SO Item No.';
        }
        field(53; "PO Description";Text[80])
        {
            Caption = 'PO Description';
        }
        field(54; "PO Description 2";Text[80])
        {
            Caption = 'PO Description 2';
        }
        field(55; "SO Unit of Measure";Code[20])
        {
            Caption = 'SO Unit of Measure';
        }
        field(56; "SO Variant Code";Code[20])
        {
            Caption = 'SO Variant Code';
        }
        field(57; "Error";Boolean)
        {
            Caption = 'Error';
        }
        field(58; "Message";Text[100])
        {
            Caption = 'Message';

        }
        field(59; "ActionRequest";Text[4])
        {
            Caption = 'Action Request';
            //TableRelation = EDI_Action_Request.Code;
            //ValidateTableRelation = False;
        }
        Field(60;ItemAction;option)
        {
            Caption = 'Item Action';
            OptionMembers = " ",Unknown,Expiered;
        }
    }

    keys
    {
        key(Key1; "Entry No.","Line No.")
        {
            Clustered = true;
        }
    }


    fieldgroups
    {
    }
   

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