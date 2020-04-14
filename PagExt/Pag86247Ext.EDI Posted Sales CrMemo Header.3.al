pageextension 86247 EDI_Posted_Sales_CrMemo_Header extends "Posted Sales Credit Memo"
{

   
    layout
    {
        addafter("E-Invoice")
        {
            field("EDI Order";"EDI Order")
            {
                ApplicationArea = All;
            }
            field("Edi Invoice No.";"Edi Invoice No.")
            {
            }
        }
    }

    actions
    {
        addfirst(processing)
        {
            action(EDISendOrderConfirmation)
            {
                ApplicationArea = Basic,Suite;
                Caption ='Send EDI';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                
                trigger OnAction();
                var
                    EDIMgt:codeunit EDI_Mgt;

                begin
                    EDIMgt.SendEDICrMemo(rec,True);
                    CurrPage.UPDATE;
                end;
            }
        }
    }
}