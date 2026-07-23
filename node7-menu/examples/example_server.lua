RegisterNetEvent('example:server:test', function(source, args)
    print(('Menu server event from %s: %s'):format(
        tostring(source),
        json.encode(args or {})
    ))
end)
