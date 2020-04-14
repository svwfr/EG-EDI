pageextension 86235 EDI_Sales_Header extends "Sales Order"
{

   
    layout
    {
        addafter("E-Invoice")
        {
            field("EDI Order";"EDI Order")
            {ApplicationArea = All;}
        }

        addfirst(FactBoxes)
        {
            part(EDIFactbox;"EDI_FactBox_SalesHeader")
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
                ApplicationArea = All;
                Caption = 'Send Edi';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                
                trigger OnAction();
                var
                    EDIMgt:codeunit EDI_Mgt;

                begin
                    EDIMgt.SendEDIOrdercomfirmation(rec);
                    CurrPage.UPDATE;
                end;
            }
        }
    }   
 }