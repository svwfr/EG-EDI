page 86241 "EDI Document Logg"
{
    caption = 'Edi Document Log';
    PageType = List;
    SourceTable = 86238;
    Editable = False;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry NO.";"Entry NO.")
                {
                    ApplicationArea = All;
                }
                field("Customer Order No.";"Customer Order No.")
                {}
                field("Edi Message ID";"Edi Message ID")
                {}
                field("Document Type";"Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No.";"Document No.")
                {
                    ApplicationArea = All;
                }
                field("Source Type";"Source Type")
                {
                    Visible = false;
                }
                field("Source No.";"Source No.")
                {}
                field("Created Date-Time";"Created Date-Time")
                {
                    ApplicationArea = All;
                }
                field("EDI message Type";"EDI message Type")
                {}
                field("Sending ID";"Sending ID")
                {}
                field(Filename;Filename)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action("Delete Logg")
            {
                Caption = 'Delete Logg';
                Image = GetOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible=False;

                trigger OnAction();
                var
                    EDILogg:Record EDI_Document_Logg;

                begin
                    EDILogg.Deleteall;
                end;
            }
            action("View EDI File")
                {
                    Caption = 'View EDI File';
                    Image = GetOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Visible=True;

                    trigger OnAction();
                    var
                        EdiOrder: record "EDI Header";
                        EdiConn: record EDI_Connection;
                        EdiMgt: Codeunit EDI_Mgt;
                        FileMgt: Codeunit "File Management";
                        Fname : text[250];
                        FilePath:text[250];

                    begin
                        EdiOrder.setrange("Entry No.","EDI Order entry No.");
                        If EdiOrder.findfirst Then begin
                            EdiConn.SetRange(GLN,EdiOrder."GLN Owner");
                            EdiConn.SetRange("GLN Type",EdiConn."GLN Type"::Agreement);
                            If EdiConn.Findfirst Then begin
                                if "Document Type" = "Document Type"::Order then
                                    FilePath := EdiMgt.GetFileNameIn(EdiConn,true)
                                else 
                                    EdiMgt.GetFileNameOut(EdiConn,'',True,FilePath,FName);

                                Fname := DelChr(FilePath,'>','\') + '\' + Filename;

                                If FileMgt.ServerFileExists(Fname) then
                                   Hyperlink(Fname);

                            End;
                        end;
                    end;
                }
        }
    }

 
}
