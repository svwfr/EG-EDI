page 86234 "EDI Types"
{
    Caption = 'Edi Types';
    PageType = List;
    SourceTable = 86233;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                 field("ID";"ID")
                {
                    ApplicationArea = All;
                }
                field("Descrition";"Description")
                {
                    ApplicationArea = All;
                }
                field("CU Import Orders";"CU Import Orders")
                {
                    ApplicationArea = All;
                }
                field("CU Export Orders";"CU Export Orders")
                {
                    ApplicationArea = All;
                }
                field("CU Export Invoice";"CU Export Invoice")
                {
                    ApplicationArea = All;
                }
                field("CU Export CrMemo";"CU Export CrMemo")
                {
                    ApplicationArea = All;
                }
                field("CU Export PRICAT";"CU Export PRICAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Codeunit to use for create Price/sales catalogue message';
                }
                field("CU Export INVRPT";"CU Export INVRPT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Codeunit to use for create Inventory Report';
                }
                field("Report Export INVRPT";"Report Export INVRPT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Report to use for create Inventory Report';
                }
            }
        }
    }
}
