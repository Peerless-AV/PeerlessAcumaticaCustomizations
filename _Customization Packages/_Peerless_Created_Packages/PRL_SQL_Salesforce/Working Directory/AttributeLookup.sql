SELECT TOP (1000) [CompanyID]
      ,[RefNoteID]
      ,[AttributeID]
      ,[Value]
      ,[PseudonymizationStatus]
      ,[NoteID]
      ,[IsActive]
      ,[UsrExportToSO]
  FROM [2024R2DEV].[dbo].[CSAnswers]
  where refnoteid = '836E6E15-24C1-EE11-8356-0A498ADF8847'


      SELECT
        ca.CompanyID,
        ca.RefNoteID,                      -- FK to Customer.AcctCD
        MAX(CASE WHEN ca.AttributeID = 'PROGROUP'   THEN ca.Value END) AS AttributePROGROUP,
        MAX(CASE WHEN ca.AttributeID = 'BILLING'    THEN ca.Value END) AS AttributeBILLING,
        MAX(CASE WHEN ca.AttributeID = 'SOREPFIRM'  THEN ca.Value END) AS AttributeSOREPFIRM,
        MAX(CASE WHEN ca.AttributeID = 'AREXPDATE'  THEN TRY_CAST(ca.Value AS DATE) END) AS AttributeARExPDATE
    FROM [dbo].[CSAnswers] ca
    WHERE ca.AttributeID IN ('PROGROUP', 'BILLING', 'SOREPFIRM', 'AREXPDATE')
    GROUP BY
        ca.CompanyID,
        ca.RefNoteID