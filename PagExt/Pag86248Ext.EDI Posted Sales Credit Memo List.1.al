pageextension 86248 EDI_Posted_SalesCrMemo_List extends "Posted Sales Credit Memos"
{

   
    layout
    {
       addafter("No. Printed") 
       {
           field("EDI Order";"EDI Order")
           {}
           field("EDI Created";"EDI Created")
           {}
           field("Edi Order Respons";"Edi Order Respons")
           {}
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