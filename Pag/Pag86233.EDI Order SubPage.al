page 86233 "EDI_Order Lines"
{
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = 86232;
    //Editable = False;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line No."; "Line No.")
                {
                }
                field("Po Item Type"; "PO Item Type")
                {
                }
                field("PO Item No."; "PO Item No.")
                {
                }
                field("PO description"; "PO description")
                {
                }
                field("PO description 2"; "PO description 2")
                {
                }
                field("Suppliers Model Number"; "Suppliers Model Number")
                {
                    Visible = False;
                }
                field("PO Quantity"; "PO Quantity")
                {
                }
                field("PO Unit Of Measure";"PO Unit Of Measure")
                {
                }
                field("PO Sales Price"; "PO Sales Price")
                {
                }
                field("PO Line Discount";"PO Line Discount")
                {
                }
                field("PO Line No.";"PO Line No.")
                {
                }
                field("PO Referance";"PO Referance")
                {
                }
                field("SO Order No."; "SO Order No.")
                {
                    trigger OnLookup(var Text : Text) : Boolean;
                    Var 
                        SalesOrder:Record "Sales Header";
                    begin
                        If SalesOrder.get(SalesOrder."Document Type"::Order,"SO Order No.") then begin
                            SalesOrder.SetRecFilter;                            
                            page.Run(Page::"Sales Order",SalesOrder);
                        End;
                    end;
                }
                field("SO Line No."; "SO Line No.")
                {
                }
                field("SO Item No."; "SO Item No.")
                {
                }
                field("SO Variant Code";"SO Variant Code")
                {
                    Visible = False;
                }
                field("SO Unit of Measure";"SO Unit of Measure")
                {
                }
                field(ItemAction;ItemAction)
                {
                }
                field("Error";"Error")
                {
                }
                field("Message";"Message")
                {
                }
            }
        }
    }

    actions
    {
    }

}

