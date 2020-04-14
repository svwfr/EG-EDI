pageextension 86240 EDI_Posted_Sales_Invoices extends "Posted Sales Invoices"
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

        addfirst(FactBoxes)
        {
             part(EDIFactbox;"EDI_FactBox_SalesInvHeader")
            {
                Caption = 'Edi Orders';
                SubPageLink = "No."=FIELD("No."); 
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
                    EDIMgt.SendEDIInvoice(rec,True);
                    CurrPage.UPDATE;
                end;
            }
        }
    }     
}