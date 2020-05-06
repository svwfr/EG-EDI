pageextension 86239 EDI_Sales_Order_List extends "Sales Order List"
{


    layout
    {
        addafter("Status")
        {
            field("EDI Order"; "EDI Order")
            {
                ApplicationArea = all;
            }
            field("EDI Created"; "EDI Created")
            {
                ApplicationArea = all;
                ToolTip = 'Date when Order Confirmation was created and sent';
            }
        }

        addfirst(FactBoxes)
        {
            part(EDIFactbox; "EDI_FactBox_SalesHeader")
            {
                Caption = 'Edi Orders';
                SubPageLink = "No." = FIELD("No.");
            }
        }
    }


    actions
    {
        addfirst(processing)
        {
            action(EDISendOrderConfirmation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send EDI';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction();
                var
                    EDIMgt: codeunit EDI_Mgt;

                begin
                    EDIMgt.SendEDIOrdercomfirmation(rec);
                    CurrPage.UPDATE;
                end;
            }
        }
    }
}