table 86239 EDI_Action_Request
{
    DataClassification = ToBeClassified;
    Caption = 'Action Request';
    DrillDownPageID = "EDI Action Request";
    LookupPageID = "EDI Action Request";

    fields
    {
        field(1; "Code"; Code[20])
        {
        }
        field(2; "Description"; Code[30])
        {
        }       
    }

    keys
    {
        key(Key1; "Code")
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