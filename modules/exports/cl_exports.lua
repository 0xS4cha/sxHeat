exports('CommitCrime', function(crime)
    SX.Crimes:Commit(crime)
end)

exports('IsPolice', function()
    return SX.Police:IsActive()
end)
