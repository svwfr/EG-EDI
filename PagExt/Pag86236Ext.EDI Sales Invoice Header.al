pageextension 86236 EDI_SalesInvoiceHeader extends "Posted Sales Invoice"
{
    layout
    {

        addafter("E-Invoice") 
        {
            field("EDI Order";"EDI Order")
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
                Caption = 'Send Edi';
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