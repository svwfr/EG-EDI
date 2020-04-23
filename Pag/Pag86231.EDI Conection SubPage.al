page 86231 "EDI - Kobling subform"
{
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = 86230;
   
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code;Code)
                {
                    Visible = False;
                    ApplicationArea = All;
                }
                field("Owner GLN";"Owner GLN")
                {
                    Visible = False;
                    ApplicationArea = All;
                }
                field("Customer No.";"Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; "Customer Name")
                {
                    ApplicationArea = All;
                }
                field("GLN"; "GLN")
                {
                    ApplicationArea = All;
                }
                field("GLN Type"; "GLN Type")
                {
                    ApplicationArea = All;
                }
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'In relation to GLN Type. Eg Type=DP reference to ship-to add. code. BY and IV will be cust.no';
                }
                field("Description"; "CodeDescription")
                {
                    ApplicationArea = All;
                }

            }
        }
    }

}   

