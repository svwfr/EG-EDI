table 86233 EDI_Types
{
    DataClassification = ToBeClassified;
    Caption = 'Edi Types';
    DrillDownPageID = 86234;
    LookupPageID = 86234;

    fields
    {
        field(1; "ID"; Code[20])
        {
            Caption = 'Id';
        }
        field(2; "Description"; Code[30])
        {
            Caption = 'Description';
        }
        field(20;"CU Import Orders"; integer)
        {
            caption = 'CU Import Orders';
        }
        field(21;"CU Export Orders"; integer)
        {
            Caption = 'CU Export Orders';
        }
        field(22;"CU Export ShipMent"; integer)
        {
            Caption = 'CU Export ShipMent';
        }
        field(23;"CU Export Invoice"; integer)
        {
            Caption = 'CU Export Invoice';
        }
        field(24;"CU Export CrMemo"; integer)
        {
            Caption = 'CU Export CrMemo';
        }
        field(25;"CU Export PRICAT"; integer)
        {
            Caption = 'CU Export Pricat';
        }   
        field(26;"CU Export INVRPT"; integer)
        {
            Caption = 'CU Export InvRpt';
        }        
        field(27;"Report Export INVRPT"; integer)
        {
            Caption = 'Report Export InvRpt';
        }                        
    }

    keys
    {
        key(Key1; "ID")
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