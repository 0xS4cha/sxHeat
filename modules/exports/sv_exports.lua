exports('ReportCrime', function(source, crime, coords, description, street)
    return SX.Heat:Report(source, crime, coords, description, street)
end)

exports('GetHeat', function(source)
    local case = SX.Heat:GetCaseBySource(source)
    return case and case.heat or 0
end)

exports('IsWanted', function(source)
    return SX.Heat:GetCaseBySource(source) ~= nil
end)

exports('ClearHeat', function(source)
    local case = SX.Heat:GetCaseBySource(source)
    if case then SX.Heat:Clear(case, 'export') end
end)

exports('GetCases', function()
    return SX.Heat:GetCases()
end)
