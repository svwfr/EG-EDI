page 86245 "EDI Setup"
{
    Caption = 'Edi Setup';
    PageType = Card;
    SourceTable = 86240;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            Group(General)
            {
                field("Item (Charge)"; "Item (Charge)")
                {
                }
                field("Automatic EDI Shipment"; "Automatic EDI Shipment")
                {
                }
                field("Automatic EDI Invoice"; "Automatic EDI Invoice")
                {
                }
                field("Use Last Order Connection (Adhock)"; "UseLastOrderConnection(Adhock)")
                {
                }

            }
            Group(Files)
            {
                Group("File Path")
                {
                    field("File Path in"; "File Path in")
                    {
                    }
                    field("File Path Archive Inn"; "File Path Archive Inn")
                    {
                    }
                    field("File Path Out"; "File Path Out")
                    {
                    }
                    field("File Path Archive Out"; "File Path Archive Out")
                    {
                    }
                }
                Group("File Name")
                {
                    field("Filter Incomming Orders"; "Filter Incomming Orders")
                    {
                    }
                    field("File Name Orders"; "File Name Orders")
                    {
                    }
                    field("File Name Shipment"; "File Name Shipment")
                    {
                    }
                    field("File Name Invoice"; "File Name Invoice")
                    {
                    }
                    field("File Name Credit Memo"; "File Name Credit Memo")
                    {
                    }
                    field("File Name INVRPT"; "File Name INVRPT")
                    {
                    }
                }
            }
        }
    }

    trigger OnOpenPage();
    begin
        If Not get Then
            INsert;
    End;
}
