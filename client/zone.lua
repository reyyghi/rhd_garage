Zone = {}

local drawtext = false
local garageTipe = 'garage'

CreateThread(function ()
    for k, v in pairs(Config.Garages) do
        if type(v.location) == 'table' then
            for i=1, #v.location do
                Utils.createGarageZone({
                    coords = v.location[i].xyz,
                    debug = false,
                    inside = function ()
                        if not Zone.drawtext then
                            
                            if not v.impound then
                                if v.gang then if not Utils.GangCheck({garage = k, gang = v.gang}) then Zone.drawtext = not Zone.drawtext return end end
                                if v.job then if not Utils.JobCheck({garage = k, job = v.job}) then Zone.drawtext = not Zone.drawtext return end end
                            end

                            Utils.createGarageRadial({
                                gType = v.impound and 'impound' or garageTipe,
                                vType = v.type or 'car',
                                garage = k,
                                coords = v.location[i]
                            })

                            Utils.drawtext('show', k:upper(), 'warehouse')
                            Zone.drawtext = not Zone.drawtext
                        end
                    end,
                    exit = function ()
                        Utils.removeRadial(v.impound and 'impound' or garageTipe)
                    end
                })
            end
        elseif type(v.location) == 'vector4' then
            Utils.createGarageZone({
                coords = v.location.xyz,
                debug = false,
                inside = function ()
                    if not Zone.drawtext then
                        if v.gang then if not Utils.GangCheck({garage = k, gang = v.gang}) then Zone.drawtext = not Zone.drawtext return end end
                        if v.job then if not Utils.JobCheck({garage = k, job = v.job}) then Zone.drawtext = not Zone.drawtext return end end

                        Utils.createGarageRadial({
                            gType = v.impound and 'impound' or garageTipe,
                            vType = v.type or 'car',
                            garage = k,
                            coords = v.location
                        })

                        Utils.drawtext('show', k:upper(), 'warehouse')
                        Zone.drawtext = not Zone.drawtext
                    end
                end,
                exit = function ()
                    Utils.removeRadial(v.impound and 'impound' or garageTipe)
                end
            })
        else
            return
        end
    end
end)

Zone.drawtext = drawtext