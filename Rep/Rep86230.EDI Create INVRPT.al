report 86230 EDI_Create_InvRPT
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Partners;EDI_Connection)
        {
            trigger OnAfterGetRecord();
            begin
                EDIMgt.CreateINVRPT(Partners);
            end;
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport();
    begin
        partners.setrange("GLN Type",partners."GLN Type"::Agreement);
        Partners.setrange(INVRPT,True);
    end;


    var
        EDIMgt: Codeunit EDI_Mgt;
}